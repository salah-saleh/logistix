# README

This README would normally document whatever steps are necessary to get the
application up and running.

Things you may want to cover:

* Ruby version

* System dependencies

* Configuration

* Database creation

* Database initialization

* How to run the test suite

* Services (job queues, cache servers, search engines, etc.)

* Deployment instructions

* ...

---

## SKU Historical Data Seeding

### SkuHistory Model
- The `SkuHistory` model stores historical snapshots of SKU stock data for analytics and export.
- Each document represents a single point in time for a given SKU, including all nested warehouse, batch, and variant data.
- Used for analytics, reporting, and historical exports.

### Seeding Historical Data
- To seed historical data for all SKUs, use the provided rake task:

```
rails sku_history:seed
```
- This generates 4-8 history points per day for the last 30 days for each SKU, matching the SKU's structure (warehouses, batches, variants, etc).
- The data is realistic and reproducible.
- If history already exists for a SKU, it will be skipped. To force overwrite, run:

```
rails sku_history:seed[force]
```

### On-the-Fly Generation (Fallback)
- If a SKU does not have historical data, the controller will (to be implemented) generate it on-the-fly using the same logic as the rake task.
- This ensures the dashboard and export features always have data to work with.

---
