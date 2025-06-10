namespace :mock_data do
  desc "Generate mock SKU data for FE development"
  task generate_skus: :environment do
    require "json"
    require "securerandom"

    sku_count = 50
    warehouse_keys = (1..5).map { |i| "wh_#{i}" }
    skus = []

    sku_count.times do |i|
      sku_code = "SKU_%03d" % (i + 1)
      # Only one of is_batch, is_bundle, or neither can be true
      type = [:batch, :bundle, :neither].sample
      is_batch = type == :batch
      is_bundle = type == :bundle

      warehouses = {}
      total_on_shelf = 0
      total_sellable = 0
      total_reserved = 0
      total_blocked = 0

      warehouse_keys.each do |wh|
        on_shelf = rand(0..20)
        reserved = rand(0..[on_shelf, 5].min)
        blocked = rand(0..[on_shelf - reserved, 3].min)
        sellable = on_shelf - reserved - blocked
        sellable = 0 if sellable < 0

        warehouses[wh] = {
          "quantity_on_shelf" => on_shelf.to_s,
          "quantity_sellable" => sellable.to_s,
          "quantity_reserved_for_orders" => reserved.to_s,
          "quantity_blocked_by_merchant" => blocked.to_s
        }
        total_on_shelf += on_shelf
        total_sellable += sellable
        total_reserved += reserved
        total_blocked += blocked
      end

      skus << {
        "sku" => sku_code,
        "is_batch" => is_batch,
        "is_bundle" => is_bundle,
        "quantity_on_shelf" => total_on_shelf.to_s,
        "quantity_sellable" => total_sellable.to_s,
        "quantity_reserved_for_orders" => total_reserved.to_s,
        "quantity_blocked_by_merchant" => total_blocked.to_s,
        "warehouses" => warehouses
      }
    end

    File.open(Rails.root.join("db", "mock_sku_data.json"), "w") do |f|
      f.write(JSON.pretty_generate(skus))
    end
    puts "Generated mock SKU data in db/mock_sku_data.json"
  end
end 