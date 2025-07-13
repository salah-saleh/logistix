# lib/tasks/mock_sku_analytics.rake
#
# This Rake task generates mock weekly analytics data for all SKUs for the past year.
# The data is saved to the SkuWeeklyAnalytics Mongoid collection.
#
# To run: rails mock_data:generate_sku_analytics
#
# The generated data includes orders, returns, velocity, and runway, with breakdowns by channel, country, city, and warehouse.
#
# This is for development/testing purposes only.

namespace :mock_data do
  desc "Generate mock weekly analytics for all SKUs for the past year"
  task generate_sku_analytics: :environment do
    require "date" # For date calculations
    require "securerandom" # For randomization

    # Define the sales channels, countries, and top cities for breakdowns
    channels = ["Shopify", "Amazon", "eBay"]
    countries = ["US", "CA", "GB", "DE", "AU"]
    cities = ["New York", "Los Angeles", "Toronto", "London", "Berlin", "Sydney"]
    warehouses = ["wh_1", "wh_2", "wh_3", "wh_4", "wh_5"]

    # Get all SKUs from the Sku collection
    skus = Sku.all.to_a
    if skus.empty?
      puts "No SKUs found. Please seed SKUs first."
      next
    end

    # Set the number of weeks (52 for a year)
    num_weeks = 52
    today = Date.today
    # Find the most recent Monday
    last_monday = today - ((today.wday - 1) % 7)

    # Remove all existing analytics data (for clean re-generation)
    SkuWeeklyAnalytics.delete_all

    skus.each do |sku|
      num_weeks.times do |i|
        # Calculate week start and end
        week_start = last_monday - (num_weeks - 1 - i) * 7
        week_end = week_start + 6

        # Generate random order/return totals
        orders_total = rand(20..200)
        returns_total = rand(0..(orders_total / 10))

        # Generate breakdowns for orders
        orders_by_channel = channels.map { |ch| [ch, rand(0..orders_total / channels.size)] }.to_h
        # Adjust to sum to orders_total
        orders_by_channel[channels.first] += orders_total - orders_by_channel.values.sum
        orders_by_country = countries.map { |c| [c, rand(0..orders_total / countries.size)] }.to_h
        orders_by_country[countries.first] += orders_total - orders_by_country.values.sum
        orders_by_city = cities.map { |city| [city, rand(0..orders_total / cities.size)] }.to_h
        orders_by_city[cities.first] += orders_total - orders_by_city.values.sum

        # Generate breakdowns for returns
        returns_by_channel = channels.map { |ch| [ch, rand(0..returns_total / channels.size)] }.to_h
        returns_by_channel[channels.first] += returns_total - returns_by_channel.values.sum
        returns_by_country = countries.map { |c| [c, rand(0..returns_total / countries.size)] }.to_h
        returns_by_country[countries.first] += returns_total - returns_by_country.values.sum
        returns_by_city = cities.map { |city| [city, rand(0..returns_total / cities.size)] }.to_h
        returns_by_city[cities.first] += returns_total - returns_by_city.values.sum

        # Generate velocity (orders per day)
        velocity_total_per_day = orders_total / 7.0
        velocity_by_warehouse = warehouses.map { |wh| [wh, (velocity_total_per_day * rand(0.7..1.3)).round(2)] }.to_h
        velocity_by_channel = channels.map { |ch| [ch, (velocity_total_per_day * rand(0.7..1.3)).round(2)] }.to_h

        # Generate runway (days of inventory left)
        # Use current inventory from SKU if available, else random
        inventory = sku.quantity_sellable || rand(100..1000)
        runway_total_days = velocity_total_per_day > 0 ? (inventory / velocity_total_per_day).round(1) : 0.0
        runway_by_warehouse = warehouses.map do |wh|
          wh_inventory = sku.warehouses&.dig(wh, "quantity_sellable")&.to_i || rand(10..200)
          wh_velocity = velocity_by_warehouse[wh] > 0 ? velocity_by_warehouse[wh] : 1.0
          [wh, (wh_inventory / wh_velocity).round(1)]
        end.to_h

        # Create the analytics record in the database
        SkuWeeklyAnalytics.create!(
          sku: sku.sku,
          week_start: week_start,
          week_end: week_end,
          orders_total: orders_total,
          orders_by_channel: orders_by_channel,
          orders_by_country: orders_by_country,
          orders_by_city: orders_by_city,
          returns_total: returns_total,
          returns_by_channel: returns_by_channel,
          returns_by_country: returns_by_country,
          returns_by_city: returns_by_city,
          velocity_total_per_day: velocity_total_per_day.round(2),
          velocity_by_warehouse: velocity_by_warehouse,
          velocity_by_channel: velocity_by_channel,
          runway_total_days: runway_total_days,
          runway_by_warehouse: runway_by_warehouse
        )
      end
      puts "Generated analytics for SKU #{sku.sku}"
    end
    puts "Generated weekly analytics for #{skus.size} SKUs for the past year."
  end
end 