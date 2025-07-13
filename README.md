# Gistix SKU Analytics

## Weekly Analytics Feature

This project now includes a comprehensive weekly analytics system for SKUs, enabling advanced reporting and insights into stock movement, sales, returns, and inventory runway.

### SkuWeeklyAnalytics Model
- Stores weekly analytics for each SKU.
- Each record represents one SKU for one week.
- Fields include:
  - `sku`: SKU code
  - `week_start`, `week_end`: Week boundaries
  - `orders_total`, `orders_by_channel`, `orders_by_country`, `orders_by_city`
  - `returns_total`, `returns_by_channel`, `returns_by_country`, `returns_by_city`
  - `velocity_total_per_day`, `velocity_by_warehouse`, `velocity_by_channel`
  - `runway_total_days`, `runway_by_warehouse`
- Used for analytics, reporting, and dashboard display.

### Generating Mock Analytics Data
- To generate mock analytics for all SKUs for the past year, run:
  ```sh
  rails mock_data:generate_sku_analytics
  ```
- This will populate the `SkuWeeklyAnalytics` collection with realistic random data for development/testing.
- Channels include Shopify, Amazon, eBay. Countries and cities are also included for breakdowns.

### Dashboard Analytics Features
- **Index Page**: Below the stock table, a new analytics table shows weekly analytics for all SKUs.
  - Filter by week, channel, warehouse.
  - Sort by orders, returns, velocity, or runway.
- **Show Page**: Each SKU detail page now includes a full weekly analytics breakdown.
  - See orders, returns, velocity, and runway, with breakdowns by channel and warehouse.

### Code Documentation
- All new code is thoroughly documented, line by line, explaining the purpose and logic of each section.
- All new fields, filters, and view logic are explained in comments.

### Libraries Used
- No new external libraries are required for the analytics feature. All logic uses built-in Ruby, Rails, and Mongoid features.

---

For any questions or to extend analytics, see the code comments or contact the project maintainer.
