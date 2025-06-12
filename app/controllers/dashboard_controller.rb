class DashboardController < ApplicationController
  require "csv"
  require "json"

  def index
    @skus = load_sku_data
    @warehouses = extract_warehouses(@skus)
    @states = ["active", "inactive"]
    @types = ["batch", "bundle", "neither"]

    # Apply filters
    @skus = filter_skus(@skus, filter_params)

    # Apply sorting
    @skus = sort_skus(@skus, filter_params[:sort_by], filter_params[:sort_order])

    # Apply pagination
    @page = (filter_params[:page] || 1).to_i
    @per_page = 10
    @total_pages = (@skus.length.to_f / @per_page).ceil
    @skus = @skus[(@page - 1) * @per_page, @per_page] || []
  end

  def export
    # Load and filter data
    skus = load_sku_data
    filtered_skus = filter_skus(skus, filter_params)
    sorted_skus = sort_skus(filtered_skus, filter_params[:sort_by], filter_params[:sort_order])

    format = filter_params[:format] || "json"
    filename = "sku_data_#{Time.now.strftime("%Y%m%d_%H%M%S")}"

    case format
    when "json"
      send_data JSON.pretty_generate(sorted_skus), filename: "#{filename}.json", type: "application/json"
    when "csv"
      csv_data = CSV.generate do |csv|
        # Write headers
        headers = ["SKU", "Type", "Variants", "State", "Total On Shelf", "Total Sellable", "Total Reserved", "Total Blocked", "Last Update"]
        warehouse_headers = extract_warehouses(skus).map do |wh|
          [
            "#{wh} On Shelf",
            "#{wh} Sellable",
            "#{wh} Reserved",
            "#{wh} Blocked",
            "#{wh} Last Update"
          ]
        end.flatten
        csv << headers + warehouse_headers

        # Write data rows
        sorted_skus.each do |sku|
          type = if sku["is_batch"]
            "batch"
          elsif sku["is_bundle"]
            "bundle"
          else
            "neither"
          end

          row = [
            sku["sku"],
            type,
            sku["has_variants"] ? "Yes" : "No",
            sku["state"],
            sku["quantity_on_shelf"],
            sku["quantity_sellable"],
            sku["quantity_reserved_for_orders"],
            sku["quantity_blocked_by_merchant"],
            sku["last_update"]
          ]

          # Add warehouse data
          extract_warehouses(skus).each do |wh|
            wh_data = sku["warehouses"][wh] || {}
            row += [
              wh_data["quantity_on_shelf"],
              wh_data["quantity_sellable"],
              wh_data["quantity_reserved_for_orders"],
              wh_data["quantity_blocked_by_merchant"],
              wh_data["last_update"]
            ]
          end

          csv << row
        end
      end
      send_data csv_data, filename: "#{filename}.csv", type: "text/csv"
    end
  end

  def import
    if request.post?
      if params[:file].present?
        begin
          file_content = params[:file].read
          skus = case File.extname(params[:file].original_filename).downcase
          when ".json"
            JSON.parse(file_content)
          when ".csv"
            parse_csv_import(file_content)
          else
            raise "Unsupported file format"
          end

          if params[:overwrite] == "1"
            # Overwrite existing data
            File.write(Rails.root.join("db", "mock_sku_data.json"), JSON.pretty_generate(skus))
            redirect_to dashboard_index_path, notice: "Data imported successfully (overwritten)."
          else
            # Merge with existing data
            existing_skus = load_sku_data
            merged_skus = merge_sku_data(existing_skus, skus)
            File.write(Rails.root.join("db", "mock_sku_data.json"), JSON.pretty_generate(merged_skus))
            redirect_to dashboard_index_path, notice: "Data imported successfully (partial update)."
          end
        rescue JSON::ParserError => e
          redirect_to dashboard_index_path, flash: { error: "Error importing data: Invalid JSON format" }
        rescue => e
          redirect_to dashboard_index_path, flash: { error: "Error importing data: #{e.message}" }
        end
      else
        redirect_to dashboard_index_path, flash: { error: "No file uploaded." }
      end
    end
  end

  def show
    @sku = load_sku_data.find { |s| s["sku"] == params[:sku] }
    if @sku.nil?
      redirect_to dashboard_index_path, flash: { error: "SKU not found" }
    end
  end

  def download
    skus = JSON.parse(File.read(Rails.root.join("db", "mock_sku_data.json")))
    sku = skus.find { |s| s["sku"] == params[:sku] }
    return head :not_found unless sku

    respond_to do |format|
      format.json { render json: sku }
      format.csv do
        # Flatten the SKU data for CSV, including warehouse data
        flattened_data = flatten_sku_data(sku)
        headers = flattened_data.keys
        csv_data = CSV.generate do |csv|
          csv << headers
          csv << headers.map { |h| flattened_data[h] }
        end
        send_data csv_data, filename: "#{sku['sku']}_current_data.csv"
      end
    end
  end

  def download_history
    skus = JSON.parse(File.read(Rails.root.join("db", "mock_sku_data.json")))
    sku = skus.find { |s| s["sku"] == params[:sku] }
    return head :not_found unless sku

    history = generate_sku_history(sku)

    respond_to do |format|
      format.json { render json: history }
      format.csv do
        # Flatten each historical data point for CSV, including warehouse data
        flattened_history = history.map { |point| flatten_sku_data(point) }
        headers = flattened_history.first.keys
        csv_data = CSV.generate do |csv|
          csv << headers
          flattened_history.each { |point| csv << headers.map { |h| point[h] } }
        end
        send_data csv_data, filename: "#{sku['sku']}_historical_data.csv"
      end
    end
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
