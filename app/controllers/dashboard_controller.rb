class DashboardController < ApplicationController
  def index
    file_path = Rails.root.join("db", "mock_sku_data.json")
    skus = JSON.parse(File.read(file_path))

    # Filtering
    if params[:sku].present?
      skus = skus.select { |sku| sku["sku"].downcase.include?(params[:sku].downcase) }
    end

    if params[:type].present?
      case params[:type]
      when "batch"
        skus = skus.select { |sku| sku["is_batch"] }
      when "bundle"
        skus = skus.select { |sku| sku["is_bundle"] }
      when "neither"
        skus = skus.select { |sku| !sku["is_batch"] && !sku["is_bundle"] }
      end
    end

    if params[:warehouse].present?
      skus = skus.select { |sku| sku["warehouses"].key?(params[:warehouse]) }
    end

    if params[:state].present?
      skus = skus.select { |sku| sku["state"] == params[:state] }
    end

    if params[:min_last_update].present?
      min_date = Date.parse(params[:min_last_update])
      skus = skus.select { |sku| Date.parse(sku["last_update"]) >= min_date }
    end

    if params[:max_last_update].present?
      max_date = Date.parse(params[:max_last_update])
      skus = skus.select { |sku| Date.parse(sku["last_update"]) <= max_date }
    end

    # Quantity range filters
    %w[quantity_on_shelf quantity_sellable quantity_reserved_for_orders quantity_blocked_by_merchant].each do |qty|
      min_param = params["min_#{qty}"]
      max_param = params["max_#{qty}"]
      if min_param.present?
        skus = skus.select { |sku| sku[qty].to_i >= min_param.to_i }
      end
      if max_param.present?
        skus = skus.select { |sku| sku[qty].to_i <= max_param.to_i }
      end
    end

    # Sorting
    sort_by = params[:sort_by].presence_in([
      "sku", "quantity_on_shelf", "quantity_sellable", "quantity_reserved_for_orders", "quantity_blocked_by_merchant", "state", "last_update"
    ]) || "sku"
    sort_dir = params[:sort_dir] == "desc" ? -1 : 1
    skus = skus.sort_by { |sku| sort_by == "sku" ? sku[sort_by] : sku[sort_by].to_i }
    skus.reverse! if sort_dir == -1

    @skus = skus
    @params = params
    @warehouse_keys = (1..5).map { |i| "wh_#{i}" }
  end

  def export
    file_path = Rails.root.join("db", "mock_sku_data.json")
    skus = JSON.parse(File.read(file_path))

    # Filtering (same as index)
    if params[:sku].present?
      skus = skus.select { |sku| sku["sku"].downcase.include?(params[:sku].downcase) }
    end
    if params[:type].present?
      case params[:type]
      when "batch"
        skus = skus.select { |sku| sku["is_batch"] }
      when "bundle"
        skus = skus.select { |sku| sku["is_bundle"] }
      when "neither"
        skus = skus.select { |sku| !sku["is_batch"] && !sku["is_bundle"] }
      end
    end
    if params[:warehouse].present?
      skus = skus.select { |sku| sku["warehouses"].key?(params[:warehouse]) }
    end
    if params[:state].present?
      skus = skus.select { |sku| sku["state"] == params[:state] }
    end
    if params[:min_last_update].present?
      min_date = Date.strptime(params[:min_last_update], "%d/%m/%Y")
      skus = skus.select { |sku| sku["warehouses"].values.any? { |wh| Date.strptime(wh["last_update"], "%d/%m/%Y %H:%M UTC") >= min_date } }
    end
    if params[:max_last_update].present?
      max_date = Date.strptime(params[:max_last_update], "%d/%m/%Y")
      skus = skus.select { |sku| sku["warehouses"].values.any? { |wh| Date.strptime(wh["last_update"], "%d/%m/%Y %H:%M UTC") <= max_date } }
    end
    %w[quantity_on_shelf quantity_sellable quantity_reserved_for_orders quantity_blocked_by_merchant].each do |qty|
      min_param = params["min_#{qty}"]
      max_param = params["max_#{qty}"]
      if min_param.present?
        skus = skus.select { |sku| sku[qty].to_i >= min_param.to_i }
      end
      if max_param.present?
        skus = skus.select { |sku| sku[qty].to_i <= max_param.to_i }
      end
    end
    sort_by = params[:sort_by].presence_in([
      "sku", "quantity_on_shelf", "quantity_sellable", "quantity_reserved_for_orders", "quantity_blocked_by_merchant", "state", "last_update"
    ]) || "sku"
    sort_dir = params[:sort_dir] == "desc" ? -1 : 1
    skus = skus.sort_by { |sku| sort_by == "sku" ? sku[sort_by] : sku[sort_by].to_i }
    skus.reverse! if sort_dir == -1

    respond_to do |format|
      format.json { render json: skus }
      format.csv do
        require 'csv'
        headers = [
          "sku", "is_batch", "is_bundle", "quantity_on_shelf", "quantity_sellable", "quantity_reserved_for_orders", "quantity_blocked_by_merchant"
        ]
        warehouse_keys = (1..5).map { |i| "wh_#{i}" }
        warehouse_headers = warehouse_keys.flat_map { |wh| [
          "#{wh}_on_shelf", "#{wh}_sellable", "#{wh}_reserved", "#{wh}_blocked"
        ] }
        csv_data = CSV.generate(headers: true) do |csv|
          csv << headers + warehouse_headers
          skus.each do |sku|
            row = headers.map { |h| sku[h] }
            row += warehouse_keys.flat_map do |wh|
              wh_data = sku["warehouses"][wh] || {}
              [
                wh_data["quantity_on_shelf"],
                wh_data["quantity_sellable"],
                wh_data["quantity_reserved_for_orders"],
                wh_data["quantity_blocked_by_merchant"]
              ]
            end
            csv << row
          end
        end
        send_data csv_data, filename: "skus_export.csv"
      end
    end
  end

  def import
    if request.post?
      file = params[:file]
      overwrite = params[:overwrite] == "1"
      if file.present?
        begin
          if file.content_type == "text/csv"
            require "csv"
            new_data = CSV.parse(file.read, headers: true).map do |row|
              {
                "sku" => row["sku"],
                "is_batch" => row["is_batch"] == "true",
                "is_bundle" => row["is_bundle"] == "true",
                "quantity_on_shelf" => row["quantity_on_shelf"],
                "quantity_sellable" => row["quantity_sellable"],
                "quantity_reserved_for_orders" => row["quantity_reserved_for_orders"],
                "quantity_blocked_by_merchant" => row["quantity_blocked_by_merchant"],
                "state" => row["state"],
                "warehouses" => JSON.parse(row["warehouses"] || "{}")
              }
            end
          else
            new_data = JSON.parse(file.read)
          end
          existing_data = JSON.parse(File.read(Rails.root.join("db", "mock_sku_data.json")))
          if overwrite
            # Overwrite all data
            File.open(Rails.root.join("db", "mock_sku_data.json"), "w") do |f|
              f.write(JSON.pretty_generate(new_data))
            end
            flash[:notice] = "Data imported successfully (overwritten)."
          else
            # Partial update: update only existing SKUs
            existing_skus = existing_data.map { |sku| sku["sku"] }
            new_data.each do |new_sku|
              if existing_skus.include?(new_sku["sku"])
                existing_data.map! { |sku| sku["sku"] == new_sku["sku"] ? new_sku : sku }
              else
                existing_data << new_sku
              end
            end
            File.open(Rails.root.join("db", "mock_sku_data.json"), "w") do |f|
              f.write(JSON.pretty_generate(existing_data))
            end
            flash[:notice] = "Data imported successfully (partial update)."
          end
        rescue => e
          flash[:error] = "Error importing data: #{e.message}"
        end
      else
        flash[:error] = "No file uploaded."
      end
      redirect_to dashboard_index_path
    end
  end
end
