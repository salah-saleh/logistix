require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Clean up the database before each test
    Mongoid.purge!
    
    # Create test data with more variety
    @sku = Sku.create!(
      sku: "TEST-SKU-001",
      is_batch: true,
      is_bundle: false,
      has_variants: true,
      quantity_on_shelf: 30,
      quantity_sellable: 12,
      quantity_reserved_for_orders: 12,
      quantity_blocked_by_merchant: 6,
      batches: {
        "b1" => {
          "quantity_on_shelf" => "2",
          "quantity_sellable" => "1",
          "quantity_reserved_for_orders" => "1",
          "quantity_blocked_by_merchant" => "0"
        },
        "b2" => {
          "quantity_on_shelf" => "4",
          "quantity_sellable" => "1",
          "quantity_reserved_for_orders" => "2",
          "quantity_blocked_by_merchant" => "1"
        },
        "b3" => {
          "quantity_on_shelf" => "6",
          "quantity_sellable" => "1",
          "quantity_reserved_for_orders" => "3",
          "quantity_blocked_by_merchant" => "2"
        }
      },
      variants: {
        "v1" => {
          "quantity_on_shelf" => "3",
          "quantity_sellable" => "2",
          "quantity_reserved_for_orders" => "1",
          "quantity_blocked_by_merchant" => "0"
        },
        "v2" => {
          "quantity_on_shelf" => "6",
          "quantity_sellable" => "3",
          "quantity_reserved_for_orders" => "2",
          "quantity_blocked_by_merchant" => "1"
        },
        "v3" => {
          "quantity_on_shelf" => "9",
          "quantity_sellable" => "4",
          "quantity_reserved_for_orders" => "3",
          "quantity_blocked_by_merchant" => "2"
        }
      },
      warehouses: {
        "wh_1" => {
          "quantity_on_shelf" => "5",
          "quantity_sellable" => "2",
          "quantity_reserved_for_orders" => "2",
          "quantity_blocked_by_merchant" => "1",
          "last_update" => "20/03/2024 10:00 UTC",
          "batches" => {
            "b1" => {
              "quantity_on_shelf" => "2",
              "quantity_sellable" => "1",
              "quantity_reserved_for_orders" => "1",
              "quantity_blocked_by_merchant" => "0"
            },
            "b2" => {
              "quantity_on_shelf" => "4",
              "quantity_sellable" => "1",
              "quantity_reserved_for_orders" => "2",
              "quantity_blocked_by_merchant" => "1"
            },
            "b3" => {
              "quantity_on_shelf" => "6",
              "quantity_sellable" => "1",
              "quantity_reserved_for_orders" => "3",
              "quantity_blocked_by_merchant" => "2"
            }
          },
          "variants" => {
            "v1" => {
              "quantity_on_shelf" => "3",
              "quantity_sellable" => "2",
              "quantity_reserved_for_orders" => "1",
              "quantity_blocked_by_merchant" => "0"
            },
            "v2" => {
              "quantity_on_shelf" => "6",
              "quantity_sellable" => "3",
              "quantity_reserved_for_orders" => "2",
              "quantity_blocked_by_merchant" => "1"
            },
            "v3" => {
              "quantity_on_shelf" => "9",
              "quantity_sellable" => "4",
              "quantity_reserved_for_orders" => "3",
              "quantity_blocked_by_merchant" => "2"
            }
          }
        },
        "wh_2" => {
          "quantity_on_shelf" => "10",
          "quantity_sellable" => "4",
          "quantity_reserved_for_orders" => "4",
          "quantity_blocked_by_merchant" => "2",
          "last_update" => "20/03/2024 10:00 UTC",
          "batches" => {
            "b1" => {
              "quantity_on_shelf" => "2",
              "quantity_sellable" => "1",
              "quantity_reserved_for_orders" => "1",
              "quantity_blocked_by_merchant" => "0"
            },
            "b2" => {
              "quantity_on_shelf" => "4",
              "quantity_sellable" => "1",
              "quantity_reserved_for_orders" => "2",
              "quantity_blocked_by_merchant" => "1"
            },
            "b3" => {
              "quantity_on_shelf" => "6",
              "quantity_sellable" => "1",
              "quantity_reserved_for_orders" => "3",
              "quantity_blocked_by_merchant" => "2"
            }
          },
          "variants" => {
            "v1" => {
              "quantity_on_shelf" => "3",
              "quantity_sellable" => "2",
              "quantity_reserved_for_orders" => "1",
              "quantity_blocked_by_merchant" => "0"
            },
            "v2" => {
              "quantity_on_shelf" => "6",
              "quantity_sellable" => "3",
              "quantity_reserved_for_orders" => "2",
              "quantity_blocked_by_merchant" => "1"
            },
            "v3" => {
              "quantity_on_shelf" => "9",
              "quantity_sellable" => "4",
              "quantity_reserved_for_orders" => "3",
              "quantity_blocked_by_merchant" => "2"
            }
          }
        }
      },
      state: "active",
      last_update: Time.current
    )

    # Create a bundle SKU with variants (random state)
    @bundle_sku = Sku.create!(
      sku: "TEST-SKU-002",
      is_batch: false,
      is_bundle: true,
      has_variants: true,
      quantity_on_shelf: 45,
      quantity_sellable: 18,
      quantity_reserved_for_orders: 18,
      quantity_blocked_by_merchant: 9,
      variants: {
        "v1" => {
          "quantity_on_shelf" => "15",
          "quantity_sellable" => "6",
          "quantity_reserved_for_orders" => "6",
          "quantity_blocked_by_merchant" => "3"
        },
        "v2" => {
          "quantity_on_shelf" => "15",
          "quantity_sellable" => "6",
          "quantity_reserved_for_orders" => "6",
          "quantity_blocked_by_merchant" => "3"
        },
        "v3" => {
          "quantity_on_shelf" => "15",
          "quantity_sellable" => "6",
          "quantity_reserved_for_orders" => "6",
          "quantity_blocked_by_merchant" => "3"
        }
      },
      warehouses: {
        "wh_1" => {
          "quantity_on_shelf" => "15",
          "quantity_sellable" => "6",
          "quantity_reserved_for_orders" => "6",
          "quantity_blocked_by_merchant" => "3",
          "last_update" => "20/03/2024 10:00 UTC",
          "variants" => {
            "v1" => {
              "quantity_on_shelf" => "5",
              "quantity_sellable" => "2",
              "quantity_reserved_for_orders" => "2",
              "quantity_blocked_by_merchant" => "1"
            },
            "v2" => {
              "quantity_on_shelf" => "5",
              "quantity_sellable" => "2",
              "quantity_reserved_for_orders" => "2",
              "quantity_blocked_by_merchant" => "1"
            },
            "v3" => {
              "quantity_on_shelf" => "5",
              "quantity_sellable" => "2",
              "quantity_reserved_for_orders" => "2",
              "quantity_blocked_by_merchant" => "1"
            }
          }
        },
        "wh_2" => {
          "quantity_on_shelf" => "30",
          "quantity_sellable" => "12",
          "quantity_reserved_for_orders" => "12",
          "quantity_blocked_by_merchant" => "6",
          "last_update" => "20/03/2024 10:00 UTC",
          "variants" => {
            "v1" => {
              "quantity_on_shelf" => "10",
              "quantity_sellable" => "4",
              "quantity_reserved_for_orders" => "4",
              "quantity_blocked_by_merchant" => "2"
            },
            "v2" => {
              "quantity_on_shelf" => "10",
              "quantity_sellable" => "4",
              "quantity_reserved_for_orders" => "4",
              "quantity_blocked_by_merchant" => "2"
            },
            "v3" => {
              "quantity_on_shelf" => "10",
              "quantity_sellable" => "4",
              "quantity_reserved_for_orders" => "4",
              "quantity_blocked_by_merchant" => "2"
            }
          }
        }
      },
      state: "inactive",
      last_update: Time.current
    )

    # Create a simple SKU without variants (random state)
    @simple_sku = Sku.create!(
      sku: "TEST-SKU-003",
      is_batch: false,
      is_bundle: false,
      has_variants: false,
      quantity_on_shelf: 20,
      quantity_sellable: 15,
      quantity_reserved_for_orders: 3,
      quantity_blocked_by_merchant: 2,
      warehouses: {
        "wh_1" => {
          "quantity_on_shelf" => "20",
          "quantity_sellable" => "15",
          "quantity_reserved_for_orders" => "3",
          "quantity_blocked_by_merchant" => "2",
          "last_update" => "20/03/2024 10:00 UTC"
        }
      },
      state: "active",
      last_update: Time.current
    )

    # Create a SKU with high blocked quantity
    @blocked_sku = Sku.create!(
      sku: "TEST-SKU-004",
      is_batch: true,
      is_bundle: false,
      has_variants: false,
      quantity_on_shelf: 50,
      quantity_sellable: 20,
      quantity_reserved_for_orders: 10,
      quantity_blocked_by_merchant: 20,
      warehouses: {
        "wh_1" => {
          "quantity_on_shelf" => "50",
          "quantity_sellable" => "20",
          "quantity_reserved_for_orders" => "10",
          "quantity_blocked_by_merchant" => "20",
          "last_update" => "20/03/2024 10:00 UTC"
        }
      },
      state: "inactive",
      last_update: Time.current
    )

    # Force persistence
    [@sku, @bundle_sku, @simple_sku, @blocked_sku].each(&:save!)
    
    # Verify the SKUs were created
    assert_not_nil @sku, "Test SKU object is nil"
    assert_not_nil @sku.id, "Test SKU has no ID"
    assert_equal "TEST-SKU-001", @sku.sku, "Test SKU has wrong SKU value"
    
    # Verify the SKU exists in the database
    found_sku = Sku.find_by(sku: @sku.sku)
    assert_not_nil found_sku, "Test SKU was not found in database"
    assert_equal @sku.id, found_sku.id, "Found SKU has different ID"
    
    # Log the SKU details for debugging
    Rails.logger.debug "Created test SKUs: #{[@sku, @bundle_sku, @simple_sku, @blocked_sku].map(&:attributes).inspect}"
  end

  test "should get index" do
    get dashboard_index_url
    assert_response :success
  end

  test "should get show" do
    get show_dashboard_url(sku: @sku.sku)
    assert_response :success
  end

  test "should get export" do
    get export_dashboard_index_url(format: :json)
    assert_response :success
  end

  test "should get download" do
    get download_dashboard_url(sku: @sku.sku, format: :json)
    assert_response :success
  end

  test "should get download history" do
    get download_history_dashboard_url(sku: @sku.sku, format: :json)
    assert_response :success
  end

  # Filtering tests
  test "should filter by state" do
    get dashboard_index_url, params: { state: "active" }
    assert_response :success
    assert_includes @response.body, "TEST-SKU-001"
    assert_not_includes @response.body, "TEST-SKU-002" # inactive
    assert_includes @response.body, "TEST-SKU-003"
    assert_not_includes @response.body, "TEST-SKU-004" # inactive
  end

  test "should filter by type batch" do
    get dashboard_index_url, params: { type: "batch" }
    assert_response :success
    assert_includes @response.body, "TEST-SKU-001"
    assert_not_includes @response.body, "TEST-SKU-002" # bundle
    assert_not_includes @response.body, "TEST-SKU-003" # neither
    assert_includes @response.body, "TEST-SKU-004"
  end

  test "should filter by type bundle" do
    get dashboard_index_url, params: { type: "bundle" }
    assert_response :success
    assert_not_includes @response.body, "TEST-SKU-001" # batch
    assert_includes @response.body, "TEST-SKU-002"
    assert_not_includes @response.body, "TEST-SKU-003" # neither
    assert_not_includes @response.body, "TEST-SKU-004" # batch
  end

  test "should filter by has variants" do
    get dashboard_index_url, params: { has_variants: "true" }
    assert_response :success
    assert_includes @response.body, "TEST-SKU-001"
    assert_includes @response.body, "TEST-SKU-002"
    assert_not_includes @response.body, "TEST-SKU-003" # has_variants: false
    assert_not_includes @response.body, "TEST-SKU-004" # has_variants: false
  end

  test "should filter by quantity ranges" do
    get dashboard_index_url, params: {
      min_on_shelf: 20,
      max_on_shelf: 40,
      min_sellable: 10,
      max_sellable: 20,
      min_reserved: 10,
      max_reserved: 20
    }
    assert_response :success
    assert_includes @response.body, "TEST-SKU-001" # 30 on shelf, 12 sellable, 12 reserved
    assert_not_includes @response.body, "TEST-SKU-002" # 45 on shelf (too high)
    assert_not_includes @response.body, "TEST-SKU-003" # 20 on shelf, 15 sellable, 3 reserved (too low)
    assert_not_includes @response.body, "TEST-SKU-004" # 50 on shelf (too high)
  end

  test "should filter by warehouse" do
    get dashboard_index_url, params: { warehouse: "wh_1" }
    assert_response :success
    assert_includes @response.body, "TEST-SKU-001"
    assert_includes @response.body, "TEST-SKU-002"
    assert_includes @response.body, "TEST-SKU-003"
    assert_includes @response.body, "TEST-SKU-004"
  end

  test "should filter by batch" do
    get dashboard_index_url, params: { batch: "b1" }
    assert_response :success
    assert_includes @response.body, "TEST-SKU-001"
    assert_not_includes @response.body, "TEST-SKU-002" # no batches
    assert_not_includes @response.body, "TEST-SKU-003" # no batches
    assert_not_includes @response.body, "TEST-SKU-004" # no batches
  end

  test "should filter by variant" do
    get dashboard_index_url, params: { variant: "v1" }
    assert_response :success
    assert_includes @response.body, "TEST-SKU-001"
    assert_includes @response.body, "TEST-SKU-002"
    assert_not_includes @response.body, "TEST-SKU-003" # no variants
    assert_not_includes @response.body, "TEST-SKU-004" # no variants
  end

  # Sorting tests
  test "should sort by quantity_on_shelf ascending" do
    get dashboard_index_url, params: { sort_by: "quantity_on_shelf", sort_order: "asc" }
    assert_response :success
    assert_match(/TEST-SKU-003.*TEST-SKU-001.*TEST-SKU-002.*TEST-SKU-004/m, @response.body)
  end

  test "should sort by quantity_on_shelf descending" do
    get dashboard_index_url, params: { sort_by: "quantity_on_shelf", sort_order: "desc" }
    assert_response :success
    assert_match(/TEST-SKU-004.*TEST-SKU-002.*TEST-SKU-001.*TEST-SKU-003/m, @response.body)
  end

  test "should sort by sku ascending" do
    get dashboard_index_url, params: { sort_by: "sku", sort_order: "asc" }
    assert_response :success
    assert_match(/TEST-SKU-001.*TEST-SKU-002.*TEST-SKU-003.*TEST-SKU-004/m, @response.body)
  end

  test "should sort by sku descending" do
    get dashboard_index_url, params: { sort_by: "sku", sort_order: "desc" }
    assert_response :success
    assert_match(/TEST-SKU-004.*TEST-SKU-003.*TEST-SKU-002.*TEST-SKU-001/m, @response.body)
  end

  test "should sort by quantity_on_shelf with warehouse filter" do
    get dashboard_index_url, params: { warehouse: "wh_1", sort_by: "quantity_on_shelf", sort_order: "desc" }
    assert_response :success
    # Parse the response body to extract displayed quantity_on_shelf values
    doc = Nokogiri::HTML(@response.body)
    values = doc.css('td').select { |td| td.text =~ /^\d+$/ }.map { |td| td.text.to_i }
    # Only check the first column of each row (skip header)
    # The table structure is: SKU | Type | Variants | State | On Shelf | ...
    # On Shelf is the 5th column (index 4)
    on_shelf_values = doc.css('tbody tr').map do |tr|
      tds = tr.css('td')
      tds[4]&.text.to_i
    end
    # Remove any nils (in case of empty rows)
    on_shelf_values.compact!
    # Check that the values are sorted descending
    assert_equal on_shelf_values, on_shelf_values.sort.reverse, "SKUs are not sorted by warehouse quantity_on_shelf desc"
  end

  # Export tests
  test "should export filtered data as json" do
    get export_dashboard_index_url(format: :json), params: { state: "active" }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data.length # Only TEST-SKU-001 and TEST-SKU-003 are active
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-001" }
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-002" } # inactive
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-003" }
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-004" } # inactive
  end

  test "should export filtered data as csv" do
    get export_dashboard_index_url(format: :csv), params: { state: "active" }
    assert_response :success
    assert_equal "text/csv", @response.content_type
    csv_data = CSV.parse(@response.body)
    assert_equal 3, csv_data.length # Header + 2 rows
    assert_equal ["TEST-SKU-001", "TEST-SKU-003"], csv_data[1..-1].map { |row| row[0] }.sort
  end

  test "should export sorted data as json" do
    get export_dashboard_index_url(format: :json), params: { sort_by: "quantity_on_shelf", sort_order: "desc" }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 4, data.length
    assert_equal ["TEST-SKU-004", "TEST-SKU-002", "TEST-SKU-001", "TEST-SKU-003"], data.map { |sku| sku["sku"] }
  end

  # Import tests
  test "should handle import with overwrite" do
    file = fixture_file_upload("test/fixtures/files/sku_data.json", "application/json")
    post import_dashboard_index_url, params: { file: file, overwrite: "1" }
    assert_redirected_to dashboard_index_url
    assert_equal "Import successful", flash[:notice]
  end

  test "should handle import without overwrite" do
    file = fixture_file_upload("test/fixtures/files/sku_data.json", "application/json")
    post import_dashboard_index_url, params: { file: file }
    assert_redirected_to dashboard_index_url
    assert_equal "Import successful", flash[:notice]
  end

  test "should handle invalid import file" do
    file = fixture_file_upload("test/fixtures/files/invalid.json", "application/json")
    post import_dashboard_index_url, params: { file: file }
    assert_redirected_to dashboard_index_url
    assert_equal "Invalid JSON file", flash[:error]
  end

  test "should handle missing import file" do
    post import_dashboard_index_url
    assert_redirected_to dashboard_index_url
    assert_equal "No file selected", flash[:error]
  end

  test "should handle import with validation errors" do
    file = fixture_file_upload("test/fixtures/files/invalid_sku_data.json", "application/json")
    post import_dashboard_index_url, params: { file: file }
    assert_redirected_to dashboard_index_url
    assert_match(/Import failed/, flash[:error])
  end

  # Blocked filtering tests
  test "should filter by minimum blocked quantity" do
    get dashboard_index_url, params: { min_blocked: 5 }
    assert_response :success
    assert_includes @response.body, "TEST-SKU-001" # 6 blocked
    assert_includes @response.body, "TEST-SKU-002" # 9 blocked
    assert_not_includes @response.body, "TEST-SKU-003" # 2 blocked
    assert_includes @response.body, "TEST-SKU-004" # 20 blocked
  end

  test "should filter by maximum blocked quantity" do
    get dashboard_index_url, params: { max_blocked: 5 }
    assert_response :success
    assert_not_includes @response.body, "TEST-SKU-001" # 6 blocked
    assert_not_includes @response.body, "TEST-SKU-002" # 9 blocked
    assert_includes @response.body, "TEST-SKU-003" # 2 blocked
    assert_not_includes @response.body, "TEST-SKU-004" # 20 blocked
  end

  test "should filter by blocked quantity range" do
    get dashboard_index_url, params: { min_blocked: 5, max_blocked: 10 }
    assert_response :success
    assert_includes @response.body, "TEST-SKU-001" # 6 blocked
    assert_includes @response.body, "TEST-SKU-002" # 9 blocked
    assert_not_includes @response.body, "TEST-SKU-003" # 2 blocked
    assert_not_includes @response.body, "TEST-SKU-004" # 20 blocked
  end

  test "should export filtered blocked data as json" do
    get export_dashboard_index_url(format: :json), params: { min_blocked: 5 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 3, data.length
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-001" && sku["quantity_blocked_by_merchant"] == 6 }
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-002" && sku["quantity_blocked_by_merchant"] == 9 }
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-004" && sku["quantity_blocked_by_merchant"] == 20 }
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-003" }
  end

  test "should export filtered blocked data as csv" do
    get export_dashboard_index_url(format: :csv), params: { min_blocked: 5 }
    assert_response :success
    assert_equal "text/csv", @response.content_type
    csv_data = CSV.parse(@response.body)
    assert_equal 4, csv_data.length # Header + 3 rows
    blocked_quantities = csv_data[1..-1].map { |row| row[8].to_i } # quantity_blocked_by_merchant column
    assert_includes blocked_quantities, 6
    assert_includes blocked_quantities, 9
    assert_includes blocked_quantities, 20
    assert_not_includes blocked_quantities, 2
  end

  # Warehouse export filtering tests
  test "should export warehouse-specific quantities when warehouse filter is applied" do
    get export_dashboard_index_url(format: :json), params: { warehouse: "wh_1" }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 4, data.length
    
    # Check that quantities match wh_1 warehouse data
    sku_001 = data.find { |sku| sku["sku"] == "TEST-SKU-001" }
    assert_equal 5, sku_001["quantity_on_shelf"] # wh_1 quantity
    assert_equal 2, sku_001["quantity_sellable"] # wh_1 quantity
    assert_equal 2, sku_001["quantity_reserved_for_orders"] # wh_1 quantity
    assert_equal 1, sku_001["quantity_blocked_by_merchant"] # wh_1 quantity
    
    sku_002 = data.find { |sku| sku["sku"] == "TEST-SKU-002" }
    assert_equal 15, sku_002["quantity_on_shelf"] # wh_1 quantity
    assert_equal 6, sku_002["quantity_sellable"] # wh_1 quantity
    assert_equal 6, sku_002["quantity_reserved_for_orders"] # wh_1 quantity
    assert_equal 3, sku_002["quantity_blocked_by_merchant"] # wh_1 quantity
    
    sku_003 = data.find { |sku| sku["sku"] == "TEST-SKU-003" }
    assert_equal 20, sku_003["quantity_on_shelf"] # wh_1 quantity
    assert_equal 15, sku_003["quantity_sellable"] # wh_1 quantity
    assert_equal 3, sku_003["quantity_reserved_for_orders"] # wh_1 quantity
    assert_equal 2, sku_003["quantity_blocked_by_merchant"] # wh_1 quantity
    
    sku_004 = data.find { |sku| sku["sku"] == "TEST-SKU-004" }
    assert_equal 50, sku_004["quantity_on_shelf"] # wh_1 quantity
    assert_equal 20, sku_004["quantity_sellable"] # wh_1 quantity
    assert_equal 10, sku_004["quantity_reserved_for_orders"] # wh_1 quantity
    assert_equal 20, sku_004["quantity_blocked_by_merchant"] # wh_1 quantity
  end

  test "should export warehouse-specific quantities as csv when warehouse filter is applied" do
    get export_dashboard_index_url(format: :csv), params: { warehouse: "wh_1" }
    assert_response :success
    assert_equal "text/csv", @response.content_type
    csv_data = CSV.parse(@response.body)
    assert_equal 5, csv_data.length # Header + 4 rows
    
    # Find TEST-SKU-001 row and check wh_1 quantities
    sku_001_row = csv_data.find { |row| row[0] == "TEST-SKU-001" }
    assert_equal "5", sku_001_row[5] # quantity_on_shelf
    assert_equal "2", sku_001_row[6] # quantity_sellable
    assert_equal "2", sku_001_row[7] # quantity_reserved_for_orders
    assert_equal "1", sku_001_row[8] # quantity_blocked_by_merchant
    
    # Find TEST-SKU-002 row and check wh_1 quantities
    sku_002_row = csv_data.find { |row| row[0] == "TEST-SKU-002" }
    assert_equal "15", sku_002_row[5] # quantity_on_shelf
    assert_equal "6", sku_002_row[6] # quantity_sellable
    assert_equal "6", sku_002_row[7] # quantity_reserved_for_orders
    assert_equal "3", sku_002_row[8] # quantity_blocked_by_merchant
  end

  test "should export warehouse-specific quantities for wh_2 when warehouse filter is applied" do
    get export_dashboard_index_url(format: :json), params: { warehouse: "wh_2" }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data.length # Only TEST-SKU-001 and TEST-SKU-002 have wh_2
    
    # Check that quantities match wh_2 warehouse data
    sku_001 = data.find { |sku| sku["sku"] == "TEST-SKU-001" }
    assert_equal 10, sku_001["quantity_on_shelf"] # wh_2 quantity
    assert_equal 4, sku_001["quantity_sellable"] # wh_2 quantity
    assert_equal 4, sku_001["quantity_reserved_for_orders"] # wh_2 quantity
    assert_equal 2, sku_001["quantity_blocked_by_merchant"] # wh_2 quantity
    
    sku_002 = data.find { |sku| sku["sku"] == "TEST-SKU-002" }
    assert_equal 30, sku_002["quantity_on_shelf"] # wh_2 quantity
    assert_equal 12, sku_002["quantity_sellable"] # wh_2 quantity
    assert_equal 12, sku_002["quantity_reserved_for_orders"] # wh_2 quantity
    assert_equal 6, sku_002["quantity_blocked_by_merchant"] # wh_2 quantity
  end

  test "should combine warehouse filter with other filters in export" do
    get export_dashboard_index_url(format: :json), params: { 
      warehouse: "wh_1", 
      min_blocked: 2,
      state: "active"
    }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 1, data.length # Only TEST-SKU-003 (active, has wh_1, and blocked >= 2)
    
    # Verify the returned SKU has wh_1 quantities
    sku = data.first
    assert_equal "TEST-SKU-003", sku["sku"]
    assert_equal 20, sku["quantity_on_shelf"]
    assert_equal 2, sku["quantity_blocked_by_merchant"]
  end

  # Stock level filters in export tests
  test "should export with min_on_shelf filter" do
    get export_dashboard_index_url(format: :json), params: { min_on_shelf: 25 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 3, data.length # TEST-SKU-001 (30), TEST-SKU-002 (45), and TEST-SKU-004 (50)
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-001" && sku["quantity_on_shelf"] == 30 }
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-002" && sku["quantity_on_shelf"] == 45 }
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-004" && sku["quantity_on_shelf"] == 50 }
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-003" } # 20 on shelf
  end

  test "should export with max_on_shelf filter" do
    get export_dashboard_index_url(format: :json), params: { max_on_shelf: 25 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 1, data.length # Only TEST-SKU-003 (20)
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-003" && sku["quantity_on_shelf"] == 20 }
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-001" } # 30 on shelf
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-002" } # 45 on shelf
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-004" } # 50 on shelf
  end

  test "should export with min_sellable filter" do
    get export_dashboard_index_url(format: :json), params: { min_sellable: 15 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 3, data.length # TEST-SKU-003 (15), TEST-SKU-002 (18), and TEST-SKU-004 (20)
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-003" && sku["quantity_sellable"] == 15 }
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-002" && sku["quantity_sellable"] == 18 }
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-004" && sku["quantity_sellable"] == 20 }
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-001" } # 12 sellable
  end

  test "should export with max_sellable filter" do
    get export_dashboard_index_url(format: :json), params: { max_sellable: 15 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data.length # TEST-SKU-001 (12) and TEST-SKU-003 (15)
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-001" && sku["quantity_sellable"] == 12 }
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-003" && sku["quantity_sellable"] == 15 }
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-002" } # 18 sellable
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-004" } # 20 sellable
  end

  test "should export with min_reserved filter" do
    get export_dashboard_index_url(format: :json), params: { min_reserved: 10 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 3, data.length # TEST-SKU-001 (12), TEST-SKU-002 (18), TEST-SKU-004 (10)
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-001" && sku["quantity_reserved_for_orders"] == 12 }
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-002" && sku["quantity_reserved_for_orders"] == 18 }
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-004" && sku["quantity_reserved_for_orders"] == 10 }
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-003" } # 3 reserved
  end

  test "should export with max_reserved filter" do
    get export_dashboard_index_url(format: :json), params: { max_reserved: 10 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data.length # TEST-SKU-003 (3) and TEST-SKU-004 (10)
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-003" && sku["quantity_reserved_for_orders"] == 3 }
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-004" && sku["quantity_reserved_for_orders"] == 10 }
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-001" } # 12 reserved
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-002" } # 18 reserved
  end

  test "should export with multiple stock level filters" do
    get export_dashboard_index_url(format: :json), params: { 
      min_on_shelf: 20,
      max_on_shelf: 40,
      min_sellable: 10,
      max_sellable: 20
    }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data.length # TEST-SKU-001 (30 on shelf, 12 sellable) and TEST-SKU-003 (20 on shelf, 15 sellable)
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-001" }
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-003" }
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-002" } # 45 on shelf (too high)
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-004" } # 50 on shelf (too high)
  end

  test "should export stock level filters as csv" do
    get export_dashboard_index_url(format: :csv), params: { min_on_shelf: 25 }
    assert_response :success
    assert_equal "text/csv", @response.content_type
    csv_data = CSV.parse(@response.body)
    assert_equal 4, csv_data.length # Header + 3 rows
    on_shelf_quantities = csv_data[1..-1].map { |row| row[5].to_i } # quantity_on_shelf column
    assert_includes on_shelf_quantities, 30
    assert_includes on_shelf_quantities, 45
    assert_includes on_shelf_quantities, 50
    assert_not_includes on_shelf_quantities, 20
  end

  test "should export with warehouse and stock level filters combined" do
    get export_dashboard_index_url(format: :json), params: { 
      warehouse: "wh_1",
      min_on_shelf: 10,
      max_on_shelf: 25
    }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data.length # TEST-SKU-002 (15) and TEST-SKU-003 (20) from wh_1
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-002" && sku["quantity_on_shelf"] == 15 }
    assert data.any? { |sku| sku["sku"] == "TEST-SKU-003" && sku["quantity_on_shelf"] == 20 }
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-001" } # 5 on shelf in wh_1 (too low)
    assert_not data.any? { |sku| sku["sku"] == "TEST-SKU-004" } # 50 on shelf in wh_1 (too high)
  end

  test "should filter by warehouse and stock levels in index" do
    # This test demonstrates the bug: stock level filters are ignored when warehouse is present
    get dashboard_index_url, params: { warehouse: "wh_1", min_blocked: 2 }
    assert_response :success
    # Should only show SKUs with blocked >= 2 in wh_1, but currently shows all SKUs in wh_1
    # TEST-SKU-001 has batches/variants with blocked=2 in wh_1
    # TEST-SKU-002 has top-level blocked=3 in wh_1 (should be included)
    # TEST-SKU-003 has top-level blocked=2 in wh_1 (should be included)
    # TEST-SKU-004 has top-level blocked=20 in wh_1 (should be included)
    assert_includes @response.body, "TEST-SKU-001" # Should be included (has blocked=2 in batches/variants)
    assert_includes @response.body, "TEST-SKU-002" # Should be included (has blocked=3 at top level)
    assert_includes @response.body, "TEST-SKU-003" # Should be included (has blocked=2 at top level)
    assert_includes @response.body, "TEST-SKU-004" # Should be included (has blocked=20 at top level)
  end
end
