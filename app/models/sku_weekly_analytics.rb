# SkuWeeklyAnalytics
#
# This model stores weekly analytics data for each SKU, including orders, returns, velocity, and runway.
# Each document represents one SKU's analytics for a single week.
#
# Fields:
#   sku: The SKU code this analytics record belongs to.
#   week_start: The start date of the week (Monday).
#   week_end: The end date of the week (Sunday).
#   orders_total: Total number of orders in the week.
#   orders_by_channel: Hash breakdown of orders by sales channel (e.g., Shopify, Amazon, eBay).
#   orders_by_country: Hash breakdown of orders by country.
#   orders_by_city: Hash breakdown of orders by top cities.
#   returns_total: Total number of returns in the week.
#   returns_by_channel: Hash breakdown of returns by sales channel.
#   returns_by_country: Hash breakdown of returns by country.
#   returns_by_city: Hash breakdown of returns by top cities.
#   velocity_total_per_day: Average number of orders sold per day in the week.
#   velocity_by_warehouse: Hash breakdown of average daily velocity per warehouse.
#   velocity_by_channel: Hash breakdown of average daily velocity per sales channel.
#   runway_total_days: Estimated days of inventory left based on velocity and available inventory.
#   runway_by_warehouse: Hash breakdown of runway per warehouse.
#   created_at, updated_at: Timestamps.
#
# This model is used for analytics and reporting purposes.

class SkuWeeklyAnalytics
  include Mongoid::Document
  include Mongoid::Timestamps

  # The SKU code this analytics record belongs to
  field "sku", type: String
  index({ sku: 1 })

  # The start date of the week (Monday)
  field "week_start", type: Date
  # The end date of the week (Sunday)
  field "week_end", type: Date
  index({ week_start: 1 })

  # Total number of orders in the week
  field "orders_total", type: Integer, default: 0
  # Orders breakdown by sales channel (e.g., Shopify, Amazon, eBay)
  field "orders_by_channel", type: Hash, default: -> { {} }
  # Orders breakdown by country
  field "orders_by_country", type: Hash, default: -> { {} }
  # Orders breakdown by top cities
  field "orders_by_city", type: Hash, default: -> { {} }

  # Total number of returns in the week
  field "returns_total", type: Integer, default: 0
  # Returns breakdown by sales channel
  field "returns_by_channel", type: Hash, default: -> { {} }
  # Returns breakdown by country
  field "returns_by_country", type: Hash, default: -> { {} }
  # Returns breakdown by top cities
  field "returns_by_city", type: Hash, default: -> { {} }

  # Average number of orders sold per day in the week
  field "velocity_total_per_day", type: Float, default: 0.0
  # Velocity breakdown by warehouse
  field "velocity_by_warehouse", type: Hash, default: -> { {} }
  # Velocity breakdown by sales channel
  field "velocity_by_channel", type: Hash, default: -> { {} }

  # Estimated days of inventory left based on velocity and available inventory
  field "runway_total_days", type: Float, default: 0.0
  # Runway breakdown by warehouse
  field "runway_by_warehouse", type: Hash, default: -> { {} }

  # Timestamps: created_at, updated_at are handled by Mongoid::Timestamps
end 