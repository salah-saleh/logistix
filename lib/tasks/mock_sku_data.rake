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

  desc "Generate mock historical SKU data for a specific SKU"
  task :generate_sku_history, [:sku_code] => :environment do |t, args|
    require "json"
    require "securerandom"

    sku_code = args[:sku_code]
    history_points = 20
    warehouse_keys = (1..5).map { |i| "wh_#{i}" }
    history = []

    # Get the current SKU data as a base
    current_sku = Sku.find_by(sku: sku_code)
    return puts "SKU not found: #{sku_code}" unless current_sku

    # Generate historical data points
    history_points.times do |i|
      # Generate a random time in the past 30 days
      timestamp = Time.now - rand(30).days - rand(24).hours - rand(60).minutes
      
      # Randomly decide if this was an API update or manual edit
      change_owner = ["API", "user_#{rand(1..5)}"].sample

      # Create a modified version of the current data
      historical_data = current_sku.as_json.deep_dup

      # Modify quantities with some random variation
      historical_data["quantity_on_shelf"] = (historical_data["quantity_on_shelf"].to_i + rand(-5..5)).to_s
      historical_data["quantity_sellable"] = (historical_data["quantity_sellable"].to_i + rand(-3..3)).to_s
      historical_data["quantity_reserved_for_orders"] = (historical_data["quantity_reserved_for_orders"].to_i + rand(-2..2)).to_s
      historical_data["quantity_blocked_by_merchant"] = (historical_data["quantity_blocked_by_merchant"].to_i + rand(-2..2)).to_s

      # Modify warehouse data
      historical_data["warehouses"].each do |wh_key, wh_data|
        wh_data["quantity_on_shelf"] = (wh_data["quantity_on_shelf"].to_i + rand(-3..3)).to_s
        wh_data["quantity_sellable"] = (wh_data["quantity_sellable"].to_i + rand(-2..2)).to_s
        wh_data["quantity_reserved_for_orders"] = (wh_data["quantity_reserved_for_orders"].to_i + rand(-1..1)).to_s
        wh_data["quantity_blocked_by_merchant"] = (wh_data["quantity_blocked_by_merchant"].to_i + rand(-1..1)).to_s
        wh_data["last_update"] = timestamp.strftime("%d/%m/%Y %H:%M UTC")

        # Modify batches if they exist
        if wh_data["batches"]
          wh_data["batches"].each do |batch_key, batch_data|
            batch_data["quantity_on_shelf"] = (batch_data["quantity_on_shelf"].to_i + rand(-2..2)).to_s
            batch_data["quantity_sellable"] = (batch_data["quantity_sellable"].to_i + rand(-1..1)).to_s
            batch_data["quantity_reserved_for_orders"] = (batch_data["quantity_reserved_for_orders"].to_i + rand(-1..1)).to_s
            batch_data["quantity_blocked_by_merchant"] = (batch_data["quantity_blocked_by_merchant"].to_i + rand(-1..1)).to_s
          end
        end

        # Modify variants if they exist
        if wh_data["variants"]
          wh_data["variants"].each do |variant_key, variant_data|
            variant_data["quantity_on_shelf"] = (variant_data["quantity_on_shelf"].to_i + rand(-2..2)).to_s
            variant_data["quantity_sellable"] = (variant_data["quantity_sellable"].to_i + rand(-1..1)).to_s
            variant_data["quantity_reserved_for_orders"] = (variant_data["quantity_reserved_for_orders"].to_i + rand(-1..1)).to_s
            variant_data["quantity_blocked_by_merchant"] = (variant_data["quantity_blocked_by_merchant"].to_i + rand(-1..1)).to_s
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