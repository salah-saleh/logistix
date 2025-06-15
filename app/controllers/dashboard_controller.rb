class DashboardController < ApplicationController
  require "csv"
  require "json"

  def index
    @skus = Sku.all
    @states = ["active", "inactive"]
    @warehouses = ["wh_1", "wh_2", "wh_3", "wh_4", "wh_5"]

    # Apply filters if present
    @skus = @skus.where(state: params[:state]) if params[:state].present?
    @skus = @skus.where(is_batch: true) if params[:type] == "batch"
    @skus = @skus.where(is_bundle: true) if params[:type] == "bundle"
    @skus = @skus.where(has_variants: true) if params[:has_variants] == "true"

    # Apply quantity range filters
    if params[:min_on_shelf].present?
      @skus = @skus.where(:quantity_on_shelf.gte => params[:min_on_shelf].to_i)
    end
    if params[:max_on_shelf].present?
      @skus = @skus.where(:quantity_on_shelf.lte => params[:max_on_shelf].to_i)
    end
    if params[:min_sellable].present?
      @skus = @skus.where(:quantity_sellable.gte => params[:min_sellable].to_i)
    end
    if params[:max_sellable].present?
      @skus = @skus.where(:quantity_sellable.lte => params[:max_sellable].to_i)
    end
    if params[:min_reserved].present?
      @skus = @skus.where(:quantity_reserved_for_orders.gte => params[:min_reserved].to_i)
    end
    if params[:max_reserved].present?
      @skus = @skus.where(:quantity_reserved_for_orders.lte => params[:max_reserved].to_i)
    end    

    # Apply sorting
    if params[:sort_by].present?
      sort_order = params[:sort_order] == "desc" ? -1 : 1
      @skus = @skus.order_by(params[:sort_by] => sort_order)
    end

    # Ensure @skus is never nil
    @skus = [] if @skus.nil?

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
    @skus = Sku.all
    respond_to do |format|
      format.json { render json: @skus }
      format.csv do
        headers = @skus.first.attributes.keys
        csv_data = CSV.generate do |csv|
          csv << headers
          @skus.each do |sku|
            csv << headers.map { |h| sku[h] }
          end
        end
        send_data csv_data, filename: "skus_export.csv"
      end
    end
  end

  def import
    if params[:file].present?
      begin
        data = JSON.parse(params[:file].read)
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

  def filter_skus(skus, params)
    skus = skus.select { |sku| sku["sku"].include?(params[:sku]) } if params[:sku].present?
    skus = skus.select { |sku| sku["state"] == params[:state] } if params[:state].present?
    skus = skus.select { |sku| sku["is_batch"] } if params[:type] == "batch"
    skus = skus.select { |sku| sku["is_bundle"] } if params[:type] == "bundle"
    skus = skus.select { |sku| !sku["is_batch"] && !sku["is_bundle"] } if params[:type] == "neither"
    skus = skus.select { |sku| sku["has_variants"] } if params[:has_variants] == "true"
    skus = skus.select { |sku| !sku["has_variants"] } if params[:has_variants] == "false"
    
    if params[:warehouse].present?
      skus = skus.select { |sku| sku["warehouses"].key?(params[:warehouse]) }
      # Update quantities to show warehouse-specific values
      skus.each do |sku|
        wh_data = sku["warehouses"][params[:warehouse]]
        sku["quantity_on_shelf"] = wh_data["quantity_on_shelf"]
        sku["quantity_sellable"] = wh_data["quantity_sellable"]
        sku["quantity_reserved_for_orders"] = wh_data["quantity_reserved_for_orders"]
        sku["quantity_blocked_by_merchant"] = wh_data["quantity_blocked_by_merchant"]
        sku["last_update"] = wh_data["last_update"]
      end
    end

    # Apply min/max stock filters
    if params[:min_on_shelf].present?
      min = params[:min_on_shelf].to_i
      skus = skus.select { |sku| sku["quantity_on_shelf"].to_i >= min }
    end

    if params[:max_on_shelf].present?
      max = params[:max_on_shelf].to_i
      skus = skus.select { |sku| sku["quantity_on_shelf"].to_i <= max }
    end

    if params[:min_sellable].present?
      min = params[:min_sellable].to_i
      skus = skus.select { |sku| sku["quantity_sellable"].to_i >= min }
    end

    if params[:max_sellable].present?
      max = params[:max_sellable].to_i
      skus = skus.select { |sku| sku["quantity_sellable"].to_i <= max }
    end

    if params[:min_reserved].present?
      min = params[:min_reserved].to_i
      skus = skus.select { |sku| sku["quantity_reserved_for_orders"].to_i >= min }
    end

    if params[:max_reserved].present?
      max = params[:max_reserved].to_i
      skus = skus.select { |sku| sku["quantity_reserved_for_orders"].to_i <= max }
    end

    if params[:min_blocked].present?
      min = params[:min_blocked].to_i
      skus = skus.select { |sku| sku["quantity_blocked_by_merchant"].to_i >= min }
    end

    if params[:max_blocked].present?
      max = params[:max_blocked].to_i
      skus = skus.select { |sku| sku["quantity_blocked_by_merchant"].to_i <= max }
    end

    skus
  end

  def sort_skus(skus, sort_by, sort_order)
    return skus unless sort_by.present?

    skus.sort_by do |sku|
      value = case sort_by
      when "sku"
        sku["sku"]
      when "type"
        if sku["is_batch"]
          "batch"
        elsif sku["is_bundle"]
          "bundle"
        else
          "neither"
        end
      when "has_variants"
        sku["has_variants"] ? 1 : 0
      when "state"
        sku["state"]
      when "quantity_on_shelf"
        sku["quantity_on_shelf"].to_i
      when "quantity_sellable"
        sku["quantity_sellable"].to_i
      when "quantity_reserved_for_orders"
        sku["quantity_reserved_for_orders"].to_i
      when "quantity_blocked_by_merchant"
        sku["quantity_blocked_by_merchant"].to_i
      when "last_update"
        Time.strptime(sku["last_update"], "%d/%m/%Y %H:%M UTC")
      else
        0
      end

      # For descending order, we'll use a negative value for numbers and reverse the string comparison
      if sort_order == "desc"
        if value.is_a?(Numeric)
          -value
        elsif value.is_a?(Time)
          -value.to_i
        else
          # For strings, we'll use a trick to reverse the comparison
          # by using a negative index to reverse the string
          value.to_s.reverse
        end
      else
        value
      end
    end
  end

  def merge_sku_data(existing_skus, new_skus)
    existing_map = existing_skus.index_by { |sku| sku["sku"] }
    new_skus.each do |new_sku|
      existing_map[new_sku["sku"]] = new_sku
    end
    existing_map.values
  end

  def parse_csv_import(csv_content)
    rows = CSV.parse(csv_content, headers: true)
    warehouses = extract_warehouses_from_csv_headers(rows.headers)
    
    rows.map do |row|
      sku = {
        "sku" => row["SKU"],
        "is_batch" => row["Type"] == "batch",
        "is_bundle" => row["Type"] == "bundle",
        "has_variants" => row["Variants"] == "Yes",
        "quantity_on_shelf" => row["Total On Shelf"],
        "quantity_sellable" => row["Total Sellable"],
        "quantity_reserved_for_orders" => row["Total Reserved"],
        "quantity_blocked_by_merchant" => row["Total Blocked"],
        "state" => row["State"],
        "last_update" => row["Last Update"],
        "warehouses" => {}
      }

      warehouses.each do |wh|
        sku["warehouses"][wh] = {
          "quantity_on_shelf" => row["#{wh} On Shelf"],
          "quantity_sellable" => row["#{wh} Sellable"],
          "quantity_reserved_for_orders" => row["#{wh} Reserved"],
          "quantity_blocked_by_merchant" => row["#{wh} Blocked"],
          "last_update" => row["#{wh} Last Update"]
        }
      end

      sku
    end
  end

  def extract_warehouses_from_csv_headers(headers)
    headers.grep(/^wh_\d+ On Shelf$/).map { |h| h.split(" ").first }
  end

  def filter_params
    params.permit(
      :sku, :type, :state, :warehouse, :has_variants,
      :sort_by, :sort_order, :page, :format,
      :min_on_shelf, :max_on_shelf,
      :min_sellable, :max_sellable,
      :min_reserved, :max_reserved,
      :min_blocked, :max_blocked
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
