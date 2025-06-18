class DashboardController < ApplicationController
  require "csv"
  require "json"

  def index
    @states = ["active", "inactive"]
    @warehouses = ["wh_1", "wh_2", "wh_3", "wh_4", "wh_5"]
    @skus = filtered_skus(params)

    # Transform SKU data to show warehouse-specific values when warehouse filter is applied
    if params[:warehouse].present?
      @skus = @skus.map do |sku|
        if sku.warehouses&.key?(params[:warehouse])
          wh_data = sku.warehouses[params[:warehouse]]
          # Create a new hash with warehouse-specific values but preserve nested structure
          {
            "sku" => sku.sku,
            "is_batch" => sku.is_batch,
            "is_bundle" => sku.is_bundle,
            "has_variants" => sku.has_variants,
            "state" => sku.state,
            "quantity_on_shelf" => wh_data["quantity_on_shelf"],
            "quantity_sellable" => wh_data["quantity_sellable"],
            "quantity_reserved_for_orders" => wh_data["quantity_reserved_for_orders"],
            "quantity_blocked_by_merchant" => wh_data["quantity_blocked_by_merchant"],
            "last_update" => wh_data["last_update"],
            "warehouses" => { params[:warehouse] => wh_data }, # Keep nested structure
            "batches" => wh_data["batches"],
            "variants" => wh_data["variants"]
          }
        else
          sku.attributes
        end
      end
      # Ruby-side sorting for warehouse-specific view
      if params[:sort_by].present?
        sort_key = params[:sort_by]
        order = params[:sort_order] == "desc" ? -1 : 1
        @skus = @skus.sort_by do |sku| 
          value = sku[sort_key]
          # Convert to integer for numeric fields, keep as string for others
          if ["quantity_on_shelf", "quantity_sellable", "quantity_reserved_for_orders", "quantity_blocked_by_merchant"].include?(sort_key)
            value.to_i
          elsif ["has_variants", "is_batch", "is_bundle"].include?(sort_key)
            # Convert boolean to string for consistent sorting
            value.to_s
          else
            value || ""
          end
        end
        @skus.reverse! if order == -1
      end
    else
      @skus = @skus.map(&:attributes)
    end

    # Apply pagination
    @page = (params[:page] || 1).to_i
    @per_page = 10
    @total_pages = (@skus.length.to_f / @per_page).ceil
    @skus = @skus[(@page - 1) * @per_page, @per_page] || []
  end

  def show
    Rails.logger.debug "Looking for SKU: #{params[:sku]}"
    @sku = Sku.where(sku: params[:sku]).first
    Rails.logger.debug "Found SKU: #{@sku.inspect}"
    if @sku.nil?
      render json: { error: "SKU not found", status: 404 }, status: :not_found
      return
    end
    render :show
  end

  def download
    Rails.logger.debug "Looking for SKU: #{params[:sku]}"
    @sku = Sku.where(sku: params[:sku]).first
    Rails.logger.debug "Found SKU: #{@sku.inspect}"
    if @sku.nil?
      render json: { error: "SKU not found", status: 404 }, status: :not_found
      return
    end

    respond_to do |format|
      format.json { render json: @sku }
      format.csv do
        # Flatten the SKU data for CSV
        flattened_data = @sku.attributes
        headers = flattened_data.keys
        csv_data = CSV.generate do |csv|
          csv << headers
          csv << headers.map { |h| flattened_data[h] }
        end
        send_data csv_data, filename: "#{@sku.sku}_current_data.csv"
      end
    end
  end

  def download_history
    Rails.logger.debug "Looking for SKU: #{params[:sku]}"
    @sku = Sku.where(sku: params[:sku]).first
    Rails.logger.debug "Found SKU: #{@sku.inspect}"
    if @sku.nil?
      render json: { error: "SKU not found", status: 404 }, status: :not_found
      return
    end

    # Generate history from the SKU's attributes
    history = [@sku.attributes]

    respond_to do |format|
      format.json { render json: history }
      format.csv do
        # Flatten each historical data point for CSV
        flattened_history = history.map { |point| point }
        headers = flattened_history.first.keys
        csv_data = CSV.generate do |csv|
          csv << headers
          flattened_history.each { |point| csv << headers.map { |h| point[h] } }
        end
        send_data csv_data, filename: "#{@sku.sku}_historical_data.csv"
      end
    end
  end

  def export
    skus = filtered_skus(params)
    warehouse = params[:warehouse]

    export_rows = skus.map do |sku|
      if warehouse.present? && sku.warehouses&.key?(warehouse)
        wh_data = sku.warehouses[warehouse]
        row = {
          "sku" => sku.sku,
          "is_batch" => sku.is_batch,
          "is_bundle" => sku.is_bundle,
          "has_variants" => sku.has_variants,
          "state" => sku.state,
          "quantity_on_shelf" => wh_data["quantity_on_shelf"].to_i,
          "quantity_sellable" => wh_data["quantity_sellable"].to_i,
          "quantity_reserved_for_orders" => wh_data["quantity_reserved_for_orders"].to_i,
          "quantity_blocked_by_merchant" => wh_data["quantity_blocked_by_merchant"].to_i,
          "last_update" => wh_data["last_update"],
          "warehouse" => warehouse,
          "batches" => wh_data["batches"],
          "variants" => wh_data["variants"]
        }
        Rails.logger.debug "EXPORT: Warehouse row for #{sku.sku}: #{row.inspect}"
        row
      else
        row = {
          "sku" => sku.sku,
          "is_batch" => sku.is_batch,
          "is_bundle" => sku.is_bundle,
          "has_variants" => sku.has_variants,
          "state" => sku.state,
          "quantity_on_shelf" => sku.quantity_on_shelf,
          "quantity_sellable" => sku.quantity_sellable,
          "quantity_reserved_for_orders" => sku.quantity_reserved_for_orders,
          "quantity_blocked_by_merchant" => sku.quantity_blocked_by_merchant,
          "last_update" => sku.last_update&.strftime("%d/%m/%Y %H:%M UTC"),
          "warehouses" => sku.warehouses,
          "batches" => sku.batches,
          "variants" => sku.variants
        }
        Rails.logger.debug "EXPORT: Global row for #{sku.sku}: #{row.inspect}"
        row
      end
    end

    Rails.logger.debug "EXPORT: Rows before quantity filter: #{export_rows.map { |r| r["sku"] }.inspect}"

    export_rows = export_rows.select do |row|
      passes_filter = true
      if params[:min_on_shelf].present?
        passes_filter = false if row["quantity_on_shelf"] < params[:min_on_shelf].to_i
      end
      if params[:max_on_shelf].present?
        passes_filter = false if row["quantity_on_shelf"] > params[:max_on_shelf].to_i
      end
      if params[:min_sellable].present?
        passes_filter = false if row["quantity_sellable"] < params[:min_sellable].to_i
      end
      if params[:max_sellable].present?
        passes_filter = false if row["quantity_sellable"] > params[:max_sellable].to_i
      end
      if params[:min_reserved].present?
        passes_filter = false if row["quantity_reserved_for_orders"] < params[:min_reserved].to_i
      end
      if params[:max_reserved].present?
        passes_filter = false if row["quantity_reserved_for_orders"] > params[:max_reserved].to_i
      end
      if params[:min_blocked].present?
        passes_filter = false if row["quantity_blocked_by_merchant"] < params[:min_blocked].to_i
      end
      if params[:max_blocked].present?
        passes_filter = false if row["quantity_blocked_by_merchant"] > params[:max_blocked].to_i
      end
      passes_filter
    end

    Rails.logger.debug "EXPORT: Rows after quantity filter: #{export_rows.map { |r| r["sku"] }.inspect}"

    respond_to do |format|
      format.json {
        render json: export_rows.map { |row|
          row["last_update"] = row["last_update"]&.is_a?(Time) ? row["last_update"].strftime("%d/%m/%Y %H:%M UTC") : row["last_update"]
          row
        }
      }
      format.csv do
        headers = ["sku", "is_batch", "is_bundle", "has_variants", "state", "quantity_on_shelf", "quantity_sellable", "quantity_reserved_for_orders", "quantity_blocked_by_merchant", "last_update"]
        csv_data = CSV.generate do |csv|
          csv << headers
          export_rows.each do |row|
            csv << [
              row["sku"],
              row["is_batch"],
              row["is_bundle"],
              row["has_variants"],
              row["state"],
              row["quantity_on_shelf"],
              row["quantity_sellable"],
              row["quantity_reserved_for_orders"],
              row["quantity_blocked_by_merchant"],
              row["last_update"]
            ]
          end
        end
        send_data csv_data, filename: "skus_export_#{Time.current.strftime("%Y%m%d_%H%M%S")}.csv", type: "text/csv"
      end
    end
  end

  def import
    if params[:file].present?
      begin
        content = params[:file].read
        data = JSON.parse(content)
        
        # Validate that data is an array
        unless data.is_a?(Array)
          flash[:error] = "Invalid JSON file"
          redirect_to dashboard_index_path
          return
        end

        # Validate each SKU entry
        data.each do |sku_data|
          unless sku_data.is_a?(Hash)
            flash[:error] = "Invalid JSON file"
            redirect_to dashboard_index_path
            return
          end

          # Check required fields
          required_fields = ["sku", "is_batch", "is_bundle", "has_variants", "state"]
          missing_fields = required_fields - sku_data.keys
          if missing_fields.any?
            flash[:error] = "Invalid JSON file"
            redirect_to dashboard_index_path
            return
          end
        end

        if params[:overwrite]
          Sku.delete_all
        end

        data.each do |sku_data|
          Sku.create!(sku_data)
        end
        flash[:notice] = "Import successful"
      rescue JSON::ParserError
        flash[:error] = "Invalid JSON file"
      rescue => e
        flash[:error] = "Import failed: #{e.message}"
      end
    else
      flash[:error] = "No file selected"
    end
    redirect_to dashboard_index_path
  end

  private

  # Recursively collect all values for a given key in a hash
  def collect_all_values(hash, key)
    values = []
    if hash.is_a?(Hash)
      hash.each do |k, v|
        if k == key
          values << v.to_i
        elsif v.is_a?(Hash)
          values.concat(collect_all_values(v, key))
        end
      end
    end
    values
  end

  def filtered_skus(params)
    skus = Sku.all
    skus = skus.where(sku: params[:sku]) if params[:sku].present?
    skus = skus.where(state: params[:state]) if params[:state].present?
    if params[:type].present?
      case params[:type]
      when "batch"
        skus = skus.where(is_batch: true, is_bundle: false)
      when "bundle"
        skus = skus.where(is_bundle: true, is_batch: false)
      when "neither"
        skus = skus.where(is_batch: false, is_bundle: false)
      end
    end
    skus = skus.where(has_variants: params[:has_variants] == "true") if params[:has_variants].present?
    skus = skus.where("batches.#{params[:batch]}.quantity_on_shelf" => { "$exists" => true }) if params[:batch].present?
    skus = skus.where("variants.#{params[:variant]}.quantity_on_shelf" => { "$exists" => true }) if params[:variant].present?
    skus = skus.where("warehouses.#{params[:warehouse]}.quantity_on_shelf" => { "$exists" => true }) if params[:warehouse].present?
    skus = skus.where(blocked: params[:blocked]) if params[:blocked].present?
    skus = skus.where(blocked: { "$ne" => true }) if params[:blocked] == "false"

    # Apply stock level filters after DB query when warehouse filter is present
    if params[:warehouse].present?
      warehouse = params[:warehouse]
      skus = skus.select do |sku|
        wh_data = sku.warehouses&.[](warehouse)
        next false unless wh_data
        
        # Collect all quantity values from the warehouse (top-level, batches, variants)
        all_on_shelf = collect_all_values(wh_data, "quantity_on_shelf")
        all_sellable = collect_all_values(wh_data, "quantity_sellable")
        all_reserved = collect_all_values(wh_data, "quantity_reserved_for_orders")
        all_blocked = collect_all_values(wh_data, "quantity_blocked_by_merchant")

        # Check if any value passes the filters
        pass = true
        if params[:min_on_shelf].present? && all_on_shelf.max.to_i < params[:min_on_shelf].to_i
          pass = false
        end
        if params[:max_on_shelf].present? && all_on_shelf.max.to_i > params[:max_on_shelf].to_i
          pass = false
        end
        if params[:min_sellable].present? && all_sellable.max.to_i < params[:min_sellable].to_i
          pass = false
        end
        if params[:max_sellable].present? && all_sellable.max.to_i > params[:max_sellable].to_i
          pass = false
        end
        if params[:min_reserved].present? && all_reserved.max.to_i < params[:min_reserved].to_i
          pass = false
        end
        if params[:max_reserved].present? && all_reserved.max.to_i > params[:max_reserved].to_i
          pass = false
        end
        if params[:min_blocked].present? && all_blocked.max.to_i < params[:min_blocked].to_i
          pass = false
        end
        if params[:max_blocked].present? && all_blocked.max.to_i > params[:max_blocked].to_i
          pass = false
        end
        pass
      end
    else
      # Only apply quantity filters in DB if warehouse filter is NOT present
      skus = skus.where(:quantity_on_shelf.gte => params[:min_on_shelf].to_i) if params[:min_on_shelf].present?
      skus = skus.where(:quantity_on_shelf.lte => params[:max_on_shelf].to_i) if params[:max_on_shelf].present?
      skus = skus.where(:quantity_sellable.gte => params[:min_sellable].to_i) if params[:min_sellable].present?
      skus = skus.where(:quantity_sellable.lte => params[:max_sellable].to_i) if params[:max_sellable].present?
      skus = skus.where(:quantity_reserved_for_orders.gte => params[:min_reserved].to_i) if params[:min_reserved].present?
      skus = skus.where(:quantity_reserved_for_orders.lte => params[:max_reserved].to_i) if params[:max_reserved].present?
      skus = skus.where(:quantity_blocked_by_merchant.gte => params[:min_blocked].to_i) if params[:min_blocked].present?
      skus = skus.where(:quantity_blocked_by_merchant.lte => params[:max_blocked].to_i) if params[:max_blocked].present?
      if params[:sort_by].present?
        sort_order = params[:sort_order] == "desc" ? -1 : 1
        skus = skus.order_by(params[:sort_by] => sort_order)
      end
    end

    skus
  end

  def load_sku_data
    file_path = Rails.root.join("db", "mock_sku_data.json")
    if File.exist?(file_path)
      JSON.parse(File.read(file_path))
    else
      []
    end
  end

  def extract_warehouses(skus)
    skus.flat_map { |sku| sku["warehouses"].keys }.uniq.sort
  end

  def filter_params
    params.permit(
      :sku, :type, :state, :warehouse, :has_variants,
      :sort_by, :sort_order, :page, :format,
      :min_on_shelf, :max_on_shelf,
      :min_sellable, :max_sellable,
      :min_reserved, :max_reserved,
      :min_blocked, :max_blocked,
      :batch, :variant,
      :blocked
    )
  end

  def flatten_sku_data(sku)
    flattened = sku.dup
    # Include warehouse data in the flattened output
    if sku["warehouses"].present?
      sku["warehouses"].each do |wh_id, wh_data|
        flattened["#{wh_id}_on_shelf"] = wh_data["quantity_on_shelf"]
        flattened["#{wh_id}_sellable"] = wh_data["quantity_sellable"]
        flattened["#{wh_id}_reserved"] = wh_data["quantity_reserved_for_orders"]
        flattened["#{wh_id}_blocked"] = wh_data["quantity_blocked_by_merchant"]
        flattened["#{wh_id}_last_update"] = wh_data["last_update"]
      end
    end
    # Remove nested data that should not be included in CSV
    flattened.delete("warehouses")
    flattened.delete("batches")
    flattened.delete("variants")
    flattened
  end

  def generate_sku_history(sku)
    history_points = 20
    history = []
    history_points.times do
      timestamp = Time.now - rand(30).days - rand(24).hours - rand(60).minutes
      change_owner = ["API", "user_#{rand(1..5)}"].sample
      historical_data = sku.deep_dup
      # Add random variation to quantities
      ["quantity_on_shelf", "quantity_sellable", "quantity_reserved_for_orders", "quantity_blocked_by_merchant"].each do |field|
        historical_data[field] = (historical_data[field].to_i + rand(-5..5)).to_s
      end
      # Add timestamp and change_owner
      historical_data["timestamp"] = timestamp.strftime("%d/%m/%Y %H:%M UTC")
      historical_data["change_owner"] = change_owner
      history << historical_data
    end
    history.sort_by { |h| Time.strptime(h["timestamp"], "%d/%m/%Y %H:%M UTC") }.reverse
  end
end
