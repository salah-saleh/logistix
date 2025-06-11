# to run: rails mock_data:generate_skus
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
      has_variants = [true, false].sample

      warehouses = {}
      total_on_shelf = 0
      total_sellable = 0
      total_reserved = 0
      total_blocked = 0

      # Randomly select 1 to 5 warehouses for this SKU
      selected_warehouses = warehouse_keys.sample(rand(1..5))
      selected_warehouses.each do |wh|
        on_shelf = rand(0..20)
        reserved = rand(0..[on_shelf, 5].min)
        blocked = rand(0..[on_shelf - reserved, 3].min)
        sellable = on_shelf - reserved - blocked
        sellable = 0 if sellable < 0

        warehouse_data = {
          "quantity_on_shelf" => on_shelf.to_s,
          "quantity_sellable" => sellable.to_s,
          "quantity_reserved_for_orders" => reserved.to_s,
          "quantity_blocked_by_merchant" => blocked.to_s,
          "last_update" => (Time.now - rand(30).days).strftime("%d/%m/%Y %H:%M UTC")
        }

        # Add batches if this is a batch SKU
        if is_batch
          batch_count = rand(1..3)
          batches = {}
          batch_count.times do |b|
            batch_on_shelf = rand(0..[on_shelf, 5].min)
            batch_reserved = rand(0..[batch_on_shelf, 3].min)
            batch_blocked = rand(0..[batch_on_shelf - batch_reserved, 2].min)
            batch_sellable = batch_on_shelf - batch_reserved - batch_blocked
            batch_sellable = 0 if batch_sellable < 0

            batches["b#{b + 1}"] = {
              "quantity_on_shelf" => batch_on_shelf.to_s,
              "quantity_sellable" => batch_sellable.to_s,
              "quantity_reserved_for_orders" => batch_reserved.to_s,
              "quantity_blocked_by_merchant" => batch_blocked.to_s
            }
          end
          warehouse_data["batches"] = batches
        end

        # Add variants if this SKU has variants
        if has_variants
          variant_count = rand(1..3)
          variants = {}
          variant_count.times do |v|
            variant_on_shelf = rand(0..[on_shelf, 5].min)
            variant_reserved = rand(0..[variant_on_shelf, 3].min)
            variant_blocked = rand(0..[variant_on_shelf - variant_reserved, 2].min)
            variant_sellable = variant_on_shelf - variant_reserved - variant_blocked
            variant_sellable = 0 if variant_sellable < 0

            variants["v#{v + 1}"] = {
              "quantity_on_shelf" => variant_on_shelf.to_s,
              "quantity_sellable" => variant_sellable.to_s,
              "quantity_reserved_for_orders" => variant_reserved.to_s,
              "quantity_blocked_by_merchant" => variant_blocked.to_s
            }
          end
          warehouse_data["variants"] = variants
        end

        warehouses[wh] = warehouse_data
        total_on_shelf += on_shelf
        total_sellable += sellable
        total_reserved += reserved
        total_blocked += blocked
      end

      # Calculate top-level last_update as the max of warehouse last_update timestamps
      last_update = warehouses.values.map { |wh| Time.strptime(wh["last_update"], "%d/%m/%Y %H:%M UTC") }.max.strftime("%d/%m/%Y %H:%M UTC")

      # Add top-level batches and variants if they exist
      top_level_data = {}
      if is_batch
        top_level_data["batches"] = warehouses.values.flat_map { |wh| wh["batches"]&.to_a || [] }.to_h
      end
      if has_variants
        top_level_data["variants"] = warehouses.values.flat_map { |wh| wh["variants"]&.to_a || [] }.to_h
      end

      skus << {
        "sku" => sku_code,
        "is_batch" => is_batch,
        "is_bundle" => is_bundle,
        "has_variants" => has_variants,
        "quantity_on_shelf" => total_on_shelf.to_s,
        "quantity_sellable" => total_sellable.to_s,
        "quantity_reserved_for_orders" => total_reserved.to_s,
        "quantity_blocked_by_merchant" => total_blocked.to_s,
        "warehouses" => warehouses,
        "state" => ["active", "inactive"].sample,
        "last_update" => last_update
      }.merge(top_level_data)
    end

    File.open(Rails.root.join("db", "mock_sku_data.json"), "w") do |f|
      f.write(JSON.pretty_generate(skus))
    end
    puts "Generated mock SKU data in db/mock_sku_data.json"
  end
end 