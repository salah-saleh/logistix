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
      "sku", "quantity_on_shelf", "quantity_sellable", "quantity_reserved_for_orders", "quantity_blocked_by_merchant"
    ]) || "sku"
    sort_dir = params[:sort_dir] == "desc" ? -1 : 1
    skus = skus.sort_by { |sku| sort_by == "sku" ? sku[sort_by] : sku[sort_by].to_i }
    skus.reverse! if sort_dir == -1

    @skus = skus
    @params = params
    @warehouse_keys = (1..5).map { |i| "wh_#{i}" }
  end
end
