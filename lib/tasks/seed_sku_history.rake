# lib/tasks/seed_sku_history.rake
#
# This rake task seeds historical stock data for all SKUs in the database.
# For each SKU, it generates 4-8 history points per day for the last 30 days,
# matching the SKU's structure (warehouses, batches, variants, etc).
#
# Usage:
#   rails sku_history:seed
#   rails sku_history:seed[force]   # Pass 'force' to overwrite existing history
#
# The generated data is realistic, reproducible, and useful for analytics/testing.

namespace :sku_history do
  desc "Seed historical stock data for all SKUs (4-8 points/day, 30 days)"
  task :seed, [:force] => :environment do |t, args|
    require "securerandom"
    require "date"

    # Optionally force overwrite
    force = args[:force].to_s == "force"

    Sku.all.each do |sku|
      if !force && SkuHistory.where(sku: sku.sku).exists?
        puts "History already exists for #{sku.sku}, skipping. Use force to overwrite."
        next
      end
      if force
        SkuHistory.where(sku: sku.sku).delete_all
      end
      # Call the shared generation method
      SkuHistory.generate_for_sku!(sku)
      puts "Seeded history for SKU #{sku.sku}"
    end
    puts "Done seeding SKU history."
  end
end

# Add the shared generation logic to the SkuHistory model
# This method can be called from both the rake task and the controller
class SkuHistory
  # Generates and saves historical data for a given SKU.
  # - Generates 4-8 points per day for the last 30 days.
  # - Matches the SKU's structure (warehouses, batches, variants, etc).
  # - Uses seeded randomness for reproducibility.
  # - Skips if history already exists for the SKU (unless force-deleted first).
  #
  # @param sku [Sku] the SKU object to generate history for
  # @return [void]
  def self.generate_for_sku!(sku)
    days = 30
    min_points = 4
    max_points = 8
    rng = Random.new(sku.sku.hash) # Seeded for reproducibility per SKU
    base_warehouses = sku.warehouses.deep_dup || {}
    base_batches = sku.batches.deep_dup || {}
    base_variants = sku.variants.deep_dup || {}
    days.times do |day_offset|
      day = Date.today - (days - 1 - day_offset)
      points = rng.rand(min_points..max_points)
      points.times do |pt|
        hour = (24.0 * pt / points).round
        minute = rng.rand(0..59)
        snapshot_time = Time.new(day.year, day.month, day.day, hour, minute, 0, "+00:00")
        pt_rng = Random.new([sku.sku.hash, day_offset, pt].hash)
        drift = ->(val) do
          delta = (val.abs * 0.1 * pt_rng.rand).round
          val + (pt_rng.rand < 0.5 ? -delta : delta)
        end
        q_on_shelf = drift.call(sku.quantity_on_shelf)
        q_sellable = [drift.call(sku.quantity_sellable), 0].max
        q_reserved = [drift.call(sku.quantity_reserved_for_orders), 0].max
        q_blocked = [drift.call(sku.quantity_blocked_by_merchant), 0].max
        whs = base_warehouses.deep_dup
        whs.each do |wh_id, wh|
          wh["quantity_on_shelf"] = drift.call(wh["quantity_on_shelf"].to_i)
          wh["quantity_sellable"] = [drift.call(wh["quantity_sellable"].to_i), 0].max
          wh["quantity_reserved_for_orders"] = [drift.call(wh["quantity_reserved_for_orders"].to_i), 0].max
          wh["quantity_blocked_by_merchant"] = [drift.call(wh["quantity_blocked_by_merchant"].to_i), 0].max
          wh["last_update"] = snapshot_time.utc.strftime("%d/%m/%Y %H:%M UTC")
          if wh["batches"]
            wh["batches"].each do |batch_id, batch|
              batch["quantity_on_shelf"] = drift.call(batch["quantity_on_shelf"].to_i)
              batch["quantity_sellable"] = [drift.call(batch["quantity_sellable"].to_i), 0].max
              batch["quantity_reserved_for_orders"] = [drift.call(batch["quantity_reserved_for_orders"].to_i), 0].max
              batch["quantity_blocked_by_merchant"] = [drift.call(batch["quantity_blocked_by_merchant"].to_i), 0].max
            end
          end
          if wh["variants"]
            wh["variants"].each do |var_id, var|
              var["quantity_on_shelf"] = drift.call(var["quantity_on_shelf"].to_i)
              var["quantity_sellable"] = [drift.call(var["quantity_sellable"].to_i), 0].max
              var["quantity_reserved_for_orders"] = [drift.call(var["quantity_reserved_for_orders"].to_i), 0].max
              var["quantity_blocked_by_merchant"] = [drift.call(var["quantity_blocked_by_merchant"].to_i), 0].max
            end
          end
        end
        batches = base_batches.deep_dup
        batches.each do |batch_id, batch|
          batch["quantity_on_shelf"] = drift.call(batch["quantity_on_shelf"].to_i)
          batch["quantity_sellable"] = [drift.call(batch["quantity_sellable"].to_i), 0].max
          batch["quantity_reserved_for_orders"] = [drift.call(batch["quantity_reserved_for_orders"].to_i), 0].max
          batch["quantity_blocked_by_merchant"] = [drift.call(batch["quantity_blocked_by_merchant"].to_i), 0].max
        end if batches
        variants = base_variants.deep_dup
        variants.each do |var_id, var|
          var["quantity_on_shelf"] = drift.call(var["quantity_on_shelf"].to_i)
          var["quantity_sellable"] = [drift.call(var["quantity_sellable"].to_i), 0].max
          var["quantity_reserved_for_orders"] = [drift.call(var["quantity_reserved_for_orders"].to_i), 0].max
          var["quantity_blocked_by_merchant"] = [drift.call(var["quantity_blocked_by_merchant"].to_i), 0].max
        end if variants
        change_owner = ["API", "system", "user_#{pt_rng.rand(1..5)}"].sample(random: pt_rng)
        SkuHistory.create!(
          sku: sku.sku,
          snapshot_time: snapshot_time,
          quantity_on_shelf: q_on_shelf,
          quantity_sellable: q_sellable,
          quantity_reserved_for_orders: q_reserved,
          quantity_blocked_by_merchant: q_blocked,
          warehouses: whs,
          batches: batches,
          variants: variants,
          change_owner: change_owner
        )
      end
    end
  end
end 