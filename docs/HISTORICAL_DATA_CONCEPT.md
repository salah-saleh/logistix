# Historical SKU Data Access Concept

## Overview

The historical SKU data system provides comprehensive access to past stock levels and changes, enabling users to debug issues, analyze trends, and understand SKU behavior over time. This system automatically generates and stores historical snapshots, making it easy to access point-in-time data for any SKU.

## Key Features

### 1. **Automatic Historical Data Generation**
- **On-demand creation**: Historical data is generated automatically when first accessed
- **Realistic patterns**: 4-8 data points per day for the last 30 days
- **Structure preservation**: Maintains warehouse, batch, and variant relationships
- **Reproducible**: Uses seeded randomness for consistent, testable data

### 2. **Enhanced SKU Show Page**
- **Current state dashboard**: Clear overview of present stock levels
- **Historical timeline**: Visual representation of stock changes over time
- **Interactive snapshots table**: Paginated list of historical data points
- **Date range filtering**: Focus on specific time periods
- **Quick downloads**: Direct access to JSON/CSV exports

### 3. **Multi-level Data Access**

#### **Current State Section**
- **Visual metrics**: Color-coded cards for different quantity types
- **Type indicators**: Batch, bundle, or standard SKU classification
- **Status badges**: Active/inactive state and variant presence
- **Last update timestamp**: When the current data was recorded

#### **Historical Timeline Section**
- **Time period selection**: 7, 30, or 90-day views
- **Chart visualization**: Stock level trends over time
- **Interactive controls**: Easy switching between periods
- **Data aggregation**: Daily summaries for trend analysis

#### **Historical Snapshots Section**
- **Paginated table**: Browse through all historical data points
- **Date filtering**: Focus on specific date ranges
- **Detailed view**: Modal popup with complete snapshot information
- **Change tracking**: See what triggered each data point

### 4. **API Endpoints for Programmatic Access**

#### **Paginated Snapshots**
```
GET /dashboard/snapshots/:sku?page=1&per_page=10&start_date=2024-01-01&end_date=2024-01-31
```
Returns paginated historical data with optional date filtering.

#### **Individual Snapshot Details**
```
GET /dashboard/snapshots/:id
```
Returns complete details for a specific historical snapshot, including full warehouse/batch/variant structure.

#### **Timeline Data**
```
GET /dashboard/timeline/:sku?days=30
```
Returns structured data for chart visualization, grouped by day.

## Use Cases for Debugging and Analysis

### 1. **Stock Level Investigations**
- **Problem**: "Why did our stock drop suddenly?"
- **Solution**: Use timeline to identify the exact time and magnitude of changes
- **Benefit**: Pinpoint whether it was a real stock movement or data issue

### 2. **Warehouse Discrepancies**
- **Problem**: "Warehouse A shows different numbers than our system"
- **Solution**: View historical snapshots to see when discrepancies started
- **Benefit**: Identify if it's a recent issue or ongoing problem

### 3. **Order Fulfillment Issues**
- **Problem**: "Orders are failing due to insufficient stock"
- **Solution**: Check historical sellable quantities to understand stock availability patterns
- **Benefit**: Determine if it's a stock issue or reservation problem

### 4. **Batch/Variant Tracking**
- **Problem**: "Specific batch is missing from inventory"
- **Solution**: Use historical data to trace batch movements over time
- **Benefit**: Understand if batch was consumed, moved, or had data issues

### 5. **System Integration Verification**
- **Problem**: "API updates aren't reflecting in our dashboard"
- **Solution**: Compare historical snapshots with API call logs
- **Benefit**: Verify data consistency and identify sync issues

## Data Structure

### **SkuHistory Model**
```ruby
{
  sku: "SKU-001",                    # SKU identifier
  snapshot_time: "2024-01-15 14:30", # When this snapshot represents
  quantity_on_shelf: 150,            # Total on shelf
  quantity_sellable: 120,            # Available for sale
  quantity_reserved_for_orders: 20,  # Reserved for pending orders
  quantity_blocked_by_merchant: 10,  # Blocked by merchant
  warehouses: {                      # Full warehouse structure
    "WH-001": {
      "quantity_on_shelf": 100,
      "quantity_sellable": 80,
      "quantity_reserved_for_orders": 15,
      "quantity_blocked_by_merchant": 5,
      "batches": { ... },            # Nested batch data
      "variants": { ... }            # Nested variant data
    }
  },
  batches: { ... },                  # Top-level batch data
  variants: { ... },                 # Top-level variant data
  change_owner: "API"                # What triggered this snapshot
}
```

## Benefits

### 1. **Immediate Debugging**
- **No waiting**: Historical data is available instantly
- **Complete context**: See full SKU structure at any point in time
- **Visual clarity**: Charts and tables make patterns obvious

### 2. **Comprehensive Analysis**
- **Trend identification**: Spot patterns in stock movements
- **Anomaly detection**: Identify unusual changes quickly
- **Root cause analysis**: Trace issues back to their source

### 3. **Data Integrity**
- **Audit trail**: Complete history of all changes
- **Verification**: Compare historical data with external systems
- **Compliance**: Maintain records for regulatory requirements

### 4. **Operational Efficiency**
- **Reduced investigation time**: Find answers quickly
- **Proactive monitoring**: Identify issues before they become problems
- **Better decision making**: Data-driven insights for inventory management

## Technical Implementation

### **Automatic Generation**
- **Triggered by**: First access to SKU show page, export, or API call
- **Frequency**: 4-8 points per day for 30 days
- **Storage**: MongoDB collection with indexed queries
- **Performance**: Optimized for fast retrieval and minimal storage

### **Data Consistency**
- **Seeded randomness**: Reproducible data for testing
- **Structure matching**: Historical data mirrors current SKU structure
- **Realistic patterns**: Stock movements follow logical business patterns

### **Scalability**
- **Indexed queries**: Fast retrieval by SKU and time
- **Pagination**: Handle large datasets efficiently
- **Caching**: Reduce database load for frequently accessed data

## Future Enhancements

### 1. **Advanced Analytics**
- **Predictive modeling**: Forecast stock levels based on historical patterns
- **Anomaly detection**: Automatic alerts for unusual stock movements
- **Trend analysis**: Identify seasonal patterns and growth trends

### 2. **Enhanced Visualization**
- **Interactive charts**: Zoom, pan, and drill-down capabilities
- **Comparison tools**: Side-by-side analysis of multiple SKUs
- **Custom dashboards**: User-defined views and metrics

### 3. **Integration Features**
- **Webhook notifications**: Real-time alerts for significant changes
- **API rate limiting**: Protect system performance
- **Export scheduling**: Automated reports and data exports

### 4. **Advanced Filtering**
- **Change type filtering**: Filter by specific types of changes
- **User-based filtering**: Show changes by specific users or systems
- **Impact analysis**: Identify SKUs affected by specific events

## Usage Examples

### **Debugging a Stock Discrepancy**
1. Navigate to the SKU show page
2. Check the current state section for immediate overview
3. Use the timeline to identify when the discrepancy started
4. Filter snapshots to the relevant date range
5. View detailed snapshots to see warehouse-level breakdowns
6. Export data for further analysis or reporting

### **Analyzing Stock Trends**
1. Select a 90-day timeline view
2. Observe patterns in stock levels over time
3. Identify peak and low periods
4. Compare with business events or seasonal patterns
5. Use insights for inventory planning

### **Investigating System Issues**
1. Check historical snapshots around the time of reported issues
2. Look for unusual patterns in change owners
3. Verify data consistency across warehouses
4. Export data for technical team analysis

This comprehensive historical data system transforms SKU debugging from a time-consuming investigation into a quick, visual, and data-rich experience that provides immediate insights and supports informed decision-making. 