# to run: rails mock_data:generate_skus
namespace :mock_data do
  desc "Generate mock SKU data for FE development"
  task generate_skus: :environment do
    require "json"

    sku_count = 50
    warehouse_keys = (1..5).map { |i| "wh_#{i}" }
    skus = []

    sku_count.times do |i|
      sku_code = "SKU_%03d" % (i + 1)
      # Use modulo to determine type consistently
      type_index = i % 3
      is_batch = type_index == 0
      is_bundle = type_index == 1
      has_variants = i % 2 == 0  # Every other SKU has variants

      warehouses = {}
      total_on_shelf = 0
      total_sellable = 0
      total_reserved = 0
      total_blocked = 0

      # Use modulo to determine number of warehouses consistently
      num_warehouses = (i % 5) + 1
      selected_warehouses = warehouse_keys.first(num_warehouses)
      
      selected_warehouses.each do |wh|
        # Use consistent quantities based on warehouse index
        wh_index = warehouse_keys.index(wh)
        on_shelf = (wh_index + 1) * 5
        reserved = (wh_index + 1) * 2
        blocked = wh_index + 1
        sellable = on_shelf - reserved - blocked
        sellable = 0 if sellable < 0

        warehouse_data = {
          "quantity_on_shelf" => on_shelf.to_s,
          "quantity_sellable" => sellable.to_s,
          "quantity_reserved_for_orders" => reserved.to_s,
          "quantity_blocked_by_merchant" => blocked.to_s,
          "last_update" => "20/03/2024 10:00 UTC"
        }

        # Add batches if this is a batch SKU
        if is_batch
          batch_count = 3
          batches = {}
          batch_count.times do |b|
            batch_on_shelf = (b + 1) * 2
            batch_reserved = b + 1
            batch_blocked = b
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
          variant_count = 3
          variants = {}
          variant_count.times do |v|
            variant_on_shelf = (v + 1) * 3
            variant_reserved = v + 1
            variant_blocked = v
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
        "state" => i % 2 == 0 ? "active" : "inactive",
        "last_update" => "20/03/2024 10:00 UTC"
      }.merge(top_level_data)
    end

    File.open(Rails.root.join("db", "mock_sku_data.json"), "w") do |f|
      f.write(JSON.pretty_generate(skus))
    end
    puts "Generated mock SKU data in db/mock_sku_data.json"
  end

  desc "Generate mock historical SKU data for a specific SKU"
  task :generate_sku_history, [:sku_code] => :environment do |t, args|
    require "json"

    sku_code = args[:sku_code]
    history_points = 20
    warehouse_keys = (1..5).map { |i| "wh_#{i}" }
    history = []

    # Get the current SKU data as a base
    current_sku = Sku.find_by(sku: sku_code)
    return puts "SKU not found: #{sku_code}" unless current_sku

    # Generate historical data points
    history_points.times do |i|
      # Generate a consistent time in the past
      timestamp = Time.now - (i * 24).hours
      
      # Alternate between API and user updates
      change_owner = i % 2 == 0 ? "API" : "user_#{i % 5 + 1}"

      # Create a modified version of the current data
      historical_data = current_sku.as_json.deep_dup

      # Modify quantities with consistent variations
      historical_data["quantity_on_shelf"] = (historical_data["quantity_on_shelf"].to_i + (i % 3 - 1)).to_s
      historical_data["quantity_sellable"] = (historical_data["quantity_sellable"].to_i + (i % 2 - 1)).to_s
      historical_data["quantity_reserved_for_orders"] = (historical_data["quantity_reserved_for_orders"].to_i + (i % 2)).to_s
      historical_data["quantity_blocked_by_merchant"] = (historical_data["quantity_blocked_by_merchant"].to_i + (i % 2)).to_s

      # Modify warehouse data
      historical_data["warehouses"].each do |wh_key, wh_data|
        wh_index = warehouse_keys.index(wh_key)
        wh_data["quantity_on_shelf"] = (wh_data["quantity_on_shelf"].to_i + (i % 3 - 1)).to_s
        wh_data["quantity_sellable"] = (wh_data["quantity_sellable"].to_i + (i % 2 - 1)).to_s
        wh_data["quantity_reserved_for_orders"] = (wh_data["quantity_reserved_for_orders"].to_i + (i % 2)).to_s
        wh_data["quantity_blocked_by_merchant"] = (wh_data["quantity_blocked_by_merchant"].to_i + (i % 2)).to_s
        wh_data["last_update"] = timestamp.strftime("%d/%m/%Y %H:%M UTC")

        # Modify batches if they exist
        if wh_data["batches"]
          wh_data["batches"].each do |batch_key, batch_data|
            batch_index = batch_key.to_i
            batch_data["quantity_on_shelf"] = (batch_data["quantity_on_shelf"].to_i + (i % 2 - 1)).to_s
            batch_data["quantity_sellable"] = (batch_data["quantity_sellable"].to_i + (i % 2)).to_s
            batch_data["quantity_reserved_for_orders"] = (batch_data["quantity_reserved_for_orders"].to_i + (i % 2)).to_s
            batch_data["quantity_blocked_by_merchant"] = (batch_data["quantity_blocked_by_merchant"].to_i + (i % 2)).to_s
          end
        end

        # Modify variants if they exist
        if wh_data["variants"]
          wh_data["variants"].each do |variant_key, variant_data|
            variant_index = variant_key.to_i
            variant_data["quantity_on_shelf"] = (variant_data["quantity_on_shelf"].to_i + (i % 2 - 1)).to_s
            variant_data["quantity_sellable"] = (variant_data["quantity_sellable"].to_i + (i % 2)).to_s
            variant_data["quantity_reserved_for_orders"] = (variant_data["quantity_reserved_for_orders"].to_i + (i % 2)).to_s
            variant_data["quantity_blocked_by_merchant"] = (variant_data["quantity_blocked_by_merchant"].to_i + (i % 2)).to_s
          end
        end
      end

      # Add metadata
      historical_data["timestamp"] = timestamp.strftime("%d/%m/%Y %H:%M UTC")
      historical_data["change_owner"] = change_owner

      history << historical_data
    end

    # Sort by timestamp descending
    history.sort_by! { |h| Time.strptime(h["timestamp"], "%d/%m/%Y %H:%M UTC") }.reverse!

    # Save to file
    output_path = Rails.root.join("db", "mock_sku_history", "#{sku_code}_history.json")
    FileUtils.mkdir_p(File.dirname(output_path))
    File.open(output_path, "w") do |f|
      f.write(JSON.pretty_generate(history))
    end
    puts "Generated historical data for SKU #{sku_code} in #{output_path}"
  end
end 