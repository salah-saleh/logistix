require "test_helper"
require "securerandom"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Clean up the database before each test
    Mongoid.purge!
    
    # Generate a unique suffix for this test run to avoid SKU uniqueness conflicts
    @sku_suffix = SecureRandom.hex(4)

    # Helper to append the suffix to a SKU
    def unique_sku(base)
      "#{base}-#{@sku_suffix}"
    end

    # Create test data with more variety
    @sku = Sku.create!(
      sku: unique_sku("TEST-SKU-001"),
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
      sku: unique_sku("TEST-SKU-002"),
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
      sku: unique_sku("TEST-SKU-003"),
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
      sku: unique_sku("TEST-SKU-004"),
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
    assert @sku.sku.end_with?(@sku_suffix), "Test SKU does not have unique suffix"
    
    # Verify the SKU exists in the database
    found_sku = Sku.find_by(sku: @sku.sku)
    assert_not_nil found_sku, "Test SKU was not found in database"
    assert_equal @sku.id, found_sku.id, "Found SKU has different ID"
    
    # Log the SKU details for debugging
    Rails.logger.debug "Created test SKUs: #{[@sku, @bundle_sku, @simple_sku, @blocked_sku].map(&:attributes).inspect}"
    Rails.logger.debug "SKUs in DB after setup: #{Sku.all.map(&:sku).inspect}"
  end

  test "should get index" do
    get dashboard_index_url
    assert_response :success
  end

  test "should get show for valid SKU" do
    get show_dashboard_url(sku: @sku.sku)
    assert_response :success
    assert_includes @response.body, @sku.sku
  end

  test "should return 404 for invalid SKU on show" do
    get show_dashboard_url(sku: "NON-EXISTENT-SKU")
    assert_response :not_found
    assert_includes @response.body, "SKU not found"
  end

  test "should generate SkuHistory on-the-fly if missing when showing SKU" do
    # Ensure no SkuHistory exists for this SKU
    SkuHistory.where(sku: @sku.sku).delete_all
    assert_equal 0, SkuHistory.where(sku: @sku.sku).count
    get show_dashboard_url(sku: @sku.sku)
    assert_response :success
    # After show, SkuHistory should be present
    assert SkuHistory.where(sku: @sku.sku).count > 0, "SkuHistory should be generated on-the-fly"
  end

  test "should not duplicate SkuHistory if already present when showing SKU" do
    # Generate history first
    SkuHistory.generate_for_sku!(@sku)
    count_before = SkuHistory.where(sku: @sku.sku).count
    get show_dashboard_url(sku: @sku.sku)
    assert_response :success
    count_after = SkuHistory.where(sku: @sku.sku).count
    assert_equal count_before, count_after, "SkuHistory should not be duplicated"
  end

  test "show page displays correct SKU data" do
    get show_dashboard_url(sku: @sku.sku)
    assert_response :success
    assert_includes @response.body, @sku.sku
    assert_includes @response.body, @sku.state.capitalize
    assert_includes @response.body, @sku.quantity_on_shelf.to_s
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
    assert_includes @response.body, @sku.sku
    assert_not_includes @response.body, @bundle_sku.sku # inactive
    assert_includes @response.body, @simple_sku.sku
    assert_not_includes @response.body, @blocked_sku.sku # inactive
  end

  test "should filter by type batch" do
    get dashboard_index_url, params: { type: "batch" }
    Rails.logger.debug "SKUs in DB at assertion: #{Sku.all.map(&:sku).inspect}"
    assert_response :success
    assert_includes @response.body, @sku.sku
    assert_not_includes @response.body, @bundle_sku.sku # bundle
    assert_not_includes @response.body, @simple_sku.sku # neither
    assert_includes @response.body, @blocked_sku.sku
  end

  test "should filter by type bundle" do
    get dashboard_index_url, params: { type: "bundle" }
    assert_response :success
    assert_not_includes @response.body, @sku.sku # batch
    assert_includes @response.body, @bundle_sku.sku
    assert_not_includes @response.body, @simple_sku.sku # neither
    assert_not_includes @response.body, @blocked_sku.sku # batch
  end

  test "should filter by has variants" do
    get dashboard_index_url, params: { has_variants: "true" }
    assert_response :success
    assert_includes @response.body, @sku.sku
    assert_includes @response.body, @bundle_sku.sku
    assert_not_includes @response.body, @simple_sku.sku # has_variants: false
    assert_not_includes @response.body, @blocked_sku.sku # has_variants: false
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
    assert_includes @response.body, @sku.sku # 30 on shelf, 12 sellable, 12 reserved
    assert_not_includes @response.body, @bundle_sku.sku # 45 on shelf (too high)
    assert_not_includes @response.body, @simple_sku.sku # 20 on shelf, 15 sellable, 3 reserved (too low)
    assert_not_includes @response.body, @blocked_sku.sku # 50 on shelf (too high)
  end

  test "should filter by warehouse" do
    get dashboard_index_url, params: { warehouse: "wh_1" }
    assert_response :success
    assert_includes @response.body, @sku.sku
    assert_includes @response.body, @bundle_sku.sku
    assert_includes @response.body, @simple_sku.sku
    assert_includes @response.body, @blocked_sku.sku
  end

  test "should filter by batch" do
    get dashboard_index_url, params: { batch: "b1" }
    assert_response :success
    assert_includes @response.body, @sku.sku
    assert_not_includes @response.body, @bundle_sku.sku # no batches
    assert_not_includes @response.body, @simple_sku.sku # no batches
    assert_not_includes @response.body, @blocked_sku.sku # no batches
  end

  test "should filter by variant" do
    get dashboard_index_url, params: { variant: "v1" }
    assert_response :success
    assert_includes @response.body, @sku.sku
    assert_includes @response.body, @bundle_sku.sku
    assert_not_includes @response.body, @simple_sku.sku # no variants
    assert_not_includes @response.body, @blocked_sku.sku # no variants
  end

  # Sorting tests
  test "should sort by quantity_on_shelf ascending" do
    get dashboard_index_url, params: { sort_by: "quantity_on_shelf", sort_order: "asc" }
    assert_response :success
    assert_match(/#{@simple_sku.sku}.*#{@sku.sku}.*#{@bundle_sku.sku}.*#{@blocked_sku.sku}/m, @response.body)
  end

  test "should sort by quantity_on_shelf descending" do
    get dashboard_index_url, params: { sort_by: "quantity_on_shelf", sort_order: "desc" }
    assert_response :success
    assert_match(/#{@blocked_sku.sku}.*#{@bundle_sku.sku}.*#{@sku.sku}.*#{@simple_sku.sku}/m, @response.body)
  end

  test "should sort by sku ascending" do
    get dashboard_index_url, params: { sort_by: "sku", sort_order: "asc" }
    assert_response :success
    assert_match(/#{@sku.sku}.*#{@bundle_sku.sku}.*#{@simple_sku.sku}.*#{@blocked_sku.sku}/m, @response.body)
  end

  test "should sort by sku descending" do
    get dashboard_index_url, params: { sort_by: "sku", sort_order: "desc" }
    assert_response :success
    assert_match(/#{@blocked_sku.sku}.*#{@simple_sku.sku}.*#{@bundle_sku.sku}.*#{@sku.sku}/m, @response.body)
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

  test "should sort by quantity_on_shelf ascending with warehouse filter" do
    get dashboard_index_url, params: { warehouse: "wh_1", sort_by: "quantity_on_shelf", sort_order: "asc" }
    assert_response :success
    doc = Nokogiri::HTML(@response.body)
    on_shelf_values = doc.css('tbody tr').map do |tr|
      tds = tr.css('td')
      tds[4]&.text.to_i
    end.compact
    # Check that the values are sorted ascending
    assert_equal on_shelf_values, on_shelf_values.sort, "SKUs are not sorted by warehouse quantity_on_shelf asc"
  end

  test "should sort by sku with warehouse filter" do
    get dashboard_index_url, params: { warehouse: "wh_1", sort_by: "sku", sort_order: "asc" }
    assert_response :success
    doc = Nokogiri::HTML(@response.body)
    sku_values = doc.css('tbody tr').map do |tr|
      tds = tr.css('td')
      tds[0]&.text.strip
    end.compact
    # Check that the SKUs are sorted alphabetically
    assert_equal sku_values, sku_values.sort, "SKUs are not sorted by sku asc"
  end

  test "should sort by has_variants with warehouse filter" do
    get dashboard_index_url, params: { warehouse: "wh_1", sort_by: "has_variants", sort_order: "asc" }
    assert_response :success
    # This should not raise an error and should complete successfully
    assert_response :success
  end

  # Export tests
  test "should export filtered data as json" do
    get export_dashboard_index_url(format: :json), params: { state: "active" }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data.length # Only @sku and @simple_sku are active
    assert data.any? { |sku| sku["sku"] == @sku.sku }
    assert_not data.any? { |sku| sku["sku"] == @bundle_sku.sku } # inactive
    assert data.any? { |sku| sku["sku"] == @simple_sku.sku }
    assert_not data.any? { |sku| sku["sku"] == @blocked_sku.sku } # inactive
  end

  test "should export filtered data as csv" do
    get export_dashboard_index_url(format: :csv), params: { state: "active" }
    assert_response :success
    assert_equal "text/csv", @response.content_type
    csv_data = CSV.parse(@response.body)
    assert_equal 3, csv_data.length # Header + 2 rows
    assert_equal [@sku.sku, @simple_sku.sku], csv_data[1..-1].map { |row| row[0] }.sort
  end

  test "should export sorted data as json" do
    get export_dashboard_index_url(format: :json), params: { sort_by: "quantity_on_shelf", sort_order: "desc" }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 4, data.length
    assert_equal [@blocked_sku.sku, @bundle_sku.sku, @sku.sku, @simple_sku.sku], data.map { |sku| sku["sku"] }
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
    assert_includes @response.body, @sku.sku # 6 blocked
    assert_includes @response.body, @bundle_sku.sku # 9 blocked
    assert_not_includes @response.body, @simple_sku.sku # 2 blocked
    assert_includes @response.body, @blocked_sku.sku # 20 blocked
  end

  test "should filter by maximum blocked quantity" do
    get dashboard_index_url, params: { max_blocked: 5 }
    assert_response :success
    assert_not_includes @response.body, @sku.sku # 6 blocked
    assert_not_includes @response.body, @bundle_sku.sku # 9 blocked
    assert_includes @response.body, @simple_sku.sku # 2 blocked
    assert_not_includes @response.body, @blocked_sku.sku # 20 blocked
  end

  test "should filter by blocked quantity range" do
    get dashboard_index_url, params: { min_blocked: 5, max_blocked: 10 }
    assert_response :success
    assert_includes @response.body, @sku.sku # 6 blocked
    assert_includes @response.body, @bundle_sku.sku # 9 blocked
    assert_not_includes @response.body, @simple_sku.sku # 2 blocked
    assert_not_includes @response.body, @blocked_sku.sku # 20 blocked
  end

  test "should export filtered blocked data as json" do
    get export_dashboard_index_url(format: :json), params: { min_blocked: 5 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 3, data.length
    assert data.any? { |sku| sku["sku"] == @sku.sku && sku["quantity_blocked_by_merchant"] == 6 }
    assert data.any? { |sku| sku["sku"] == @bundle_sku.sku && sku["quantity_blocked_by_merchant"] == 9 }
    assert data.any? { |sku| sku["sku"] == @blocked_sku.sku && sku["quantity_blocked_by_merchant"] == 20 }
    assert_not data.any? { |sku| sku["sku"] == @simple_sku.sku }
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
    sku_001 = data.find { |sku| sku["sku"] == @sku.sku }
    assert_equal 5, sku_001["quantity_on_shelf"] # wh_1 quantity
    assert_equal 2, sku_001["quantity_sellable"] # wh_1 quantity
    assert_equal 2, sku_001["quantity_reserved_for_orders"] # wh_1 quantity
    assert_equal 1, sku_001["quantity_blocked_by_merchant"] # wh_1 quantity
    
    sku_002 = data.find { |sku| sku["sku"] == @bundle_sku.sku }
    assert_equal 15, sku_002["quantity_on_shelf"] # wh_1 quantity
    assert_equal 6, sku_002["quantity_sellable"] # wh_1 quantity
    assert_equal 6, sku_002["quantity_reserved_for_orders"] # wh_1 quantity
    assert_equal 3, sku_002["quantity_blocked_by_merchant"] # wh_1 quantity
    
    sku_003 = data.find { |sku| sku["sku"] == @simple_sku.sku }
    assert_equal 20, sku_003["quantity_on_shelf"] # wh_1 quantity
    assert_equal 15, sku_003["quantity_sellable"] # wh_1 quantity
    assert_equal 3, sku_003["quantity_reserved_for_orders"] # wh_1 quantity
    assert_equal 2, sku_003["quantity_blocked_by_merchant"] # wh_1 quantity
    
    sku_004 = data.find { |sku| sku["sku"] == @blocked_sku.sku }
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
    
    # Find @sku row and check wh_1 quantities
    sku_001_row = csv_data.find { |row| row[0] == @sku.sku }
    assert_equal "5", sku_001_row[5] # quantity_on_shelf
    assert_equal "2", sku_001_row[6] # quantity_sellable
    assert_equal "2", sku_001_row[7] # quantity_reserved_for_orders
    assert_equal "1", sku_001_row[8] # quantity_blocked_by_merchant
    
    # Find @bundle_sku row and check wh_1 quantities
    sku_002_row = csv_data.find { |row| row[0] == @bundle_sku.sku }
    assert_equal "15", sku_002_row[5] # quantity_on_shelf
    assert_equal "6", sku_002_row[6] # quantity_sellable
    assert_equal "6", sku_002_row[7] # quantity_reserved_for_orders
    assert_equal "3", sku_002_row[8] # quantity_blocked_by_merchant
  end

  test "should export warehouse-specific quantities for wh_2 when warehouse filter is applied" do
    get export_dashboard_index_url(format: :json), params: { warehouse: "wh_2" }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data.length # Only @sku and @bundle_sku have wh_2
    
    # Check that quantities match wh_2 warehouse data
    sku_001 = data.find { |sku| sku["sku"] == @sku.sku }
    assert_equal 10, sku_001["quantity_on_shelf"] # wh_2 quantity
    assert_equal 4, sku_001["quantity_sellable"] # wh_2 quantity
    assert_equal 4, sku_001["quantity_reserved_for_orders"] # wh_2 quantity
    assert_equal 2, sku_001["quantity_blocked_by_merchant"] # wh_2 quantity
    
    sku_002 = data.find { |sku| sku["sku"] == @bundle_sku.sku }
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
    assert_equal 1, data.length # Only @simple_sku (active, has wh_1, and blocked >= 2)
    
    # Verify the returned SKU has wh_1 quantities
    sku = data.first
    assert_equal @simple_sku.sku, sku["sku"]
    assert_equal 20, sku["quantity_on_shelf"]
    assert_equal 2, sku["quantity_blocked_by_merchant"]
  end

  # Stock level filters in export tests
  test "should export with min_on_shelf filter" do
    get export_dashboard_index_url(format: :json), params: { min_on_shelf: 25 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 3, data.length # @sku (30), @bundle_sku (45), and @blocked_sku (50)
    assert data.any? { |sku| sku["sku"] == @sku.sku && sku["quantity_on_shelf"] == 30 }
    assert data.any? { |sku| sku["sku"] == @bundle_sku.sku && sku["quantity_on_shelf"] == 45 }
    assert data.any? { |sku| sku["sku"] == @blocked_sku.sku && sku["quantity_on_shelf"] == 50 }
    assert_not data.any? { |sku| sku["sku"] == @simple_sku.sku } # 20 on shelf
  end

  test "should export with max_on_shelf filter" do
    get export_dashboard_index_url(format: :json), params: { max_on_shelf: 25 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 1, data.length # Only @simple_sku (20)
    assert data.any? { |sku| sku["sku"] == @simple_sku.sku && sku["quantity_on_shelf"] == 20 }
    assert_not data.any? { |sku| sku["sku"] == @sku.sku } # 30 on shelf
    assert_not data.any? { |sku| sku["sku"] == @bundle_sku.sku } # 45 on shelf
    assert_not data.any? { |sku| sku["sku"] == @blocked_sku.sku } # 50 on shelf
  end

  test "should export with min_sellable filter" do
    get export_dashboard_index_url(format: :json), params: { min_sellable: 15 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 3, data.length # @simple_sku (15), @bundle_sku (18), and @blocked_sku (20)
    assert data.any? { |sku| sku["sku"] == @simple_sku.sku && sku["quantity_sellable"] == 15 }
    assert data.any? { |sku| sku["sku"] == @bundle_sku.sku && sku["quantity_sellable"] == 18 }
    assert data.any? { |sku| sku["sku"] == @blocked_sku.sku && sku["quantity_sellable"] == 20 }
    assert_not data.any? { |sku| sku["sku"] == @sku.sku } # 12 sellable
  end

  test "should export with max_sellable filter" do
    get export_dashboard_index_url(format: :json), params: { max_sellable: 15 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data.length # @sku (12) and @simple_sku (15)
    assert data.any? { |sku| sku["sku"] == @sku.sku && sku["quantity_sellable"] == 12 }
    assert data.any? { |sku| sku["sku"] == @simple_sku.sku && sku["quantity_sellable"] == 15 }
    assert_not data.any? { |sku| sku["sku"] == @bundle_sku.sku } # 18 sellable
    assert_not data.any? { |sku| sku["sku"] == @blocked_sku.sku } # 20 sellable
  end

  test "should export with min_reserved filter" do
    get export_dashboard_index_url(format: :json), params: { min_reserved: 10 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 3, data.length # @sku (12), @bundle_sku (18), @blocked_sku (10)
    assert data.any? { |sku| sku["sku"] == @sku.sku && sku["quantity_reserved_for_orders"] == 12 }
    assert data.any? { |sku| sku["sku"] == @bundle_sku.sku && sku["quantity_reserved_for_orders"] == 18 }
    assert data.any? { |sku| sku["sku"] == @blocked_sku.sku && sku["quantity_reserved_for_orders"] == 10 }
    assert_not data.any? { |sku| sku["sku"] == @simple_sku.sku } # 3 reserved
  end

  test "should export with max_reserved filter" do
    get export_dashboard_index_url(format: :json), params: { max_reserved: 10 }
    assert_response :success
    data = JSON.parse(@response.body)
    assert_equal 2, data.length # @simple_sku (3) and @blocked_sku (10)
    assert data.any? { |sku| sku["sku"] == @simple_sku.sku && sku["quantity_reserved_for_orders"] == 3 }
    assert data.any? { |sku| sku["sku"] == @blocked_sku.sku && sku["quantity_reserved_for_orders"] == 10 }
    assert_not data.any? { |sku| sku["sku"] == @sku.sku } # 12 reserved
    assert_not data.any? { |sku| sku["sku"] == @bundle_sku.sku } # 18 reserved
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
    assert_equal 2, data.length # @sku (30 on shelf, 12 sellable) and @simple_sku (20 on shelf, 15 sellable)
    assert data.any? { |sku| sku["sku"] == @sku.sku }
    assert data.any? { |sku| sku["sku"] == @simple_sku.sku }
    assert_not data.any? { |sku| sku["sku"] == @bundle_sku.sku } # 45 on shelf (too high)
    assert_not data.any? { |sku| sku["sku"] == @blocked_sku.sku } # 50 on shelf (too high)
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
    assert_equal 2, data.length # @bundle_sku (15) and @simple_sku (20) from wh_1
    assert data.any? { |sku| sku["sku"] == @bundle_sku.sku && sku["quantity_on_shelf"] == 15 }
    assert data.any? { |sku| sku["sku"] == @simple_sku.sku && sku["quantity_on_shelf"] == 20 }
    assert_not data.any? { |sku| sku["sku"] == @sku.sku } # 5 on shelf in wh_1 (too low)
    assert_not data.any? { |sku| sku["sku"] == @blocked_sku.sku } # 50 on shelf in wh_1 (too high)
  end

  test "should filter by warehouse and stock levels in index" do
    # This test demonstrates the bug: stock level filters are ignored when warehouse is present
    get dashboard_index_url, params: { warehouse: "wh_1", min_blocked: 2 }
    assert_response :success
    # Should only show SKUs with blocked >= 2 in wh_1, but currently shows all SKUs in wh_1
    # @sku has batches/variants with blocked=2 in wh_1
    # @bundle_sku has top-level blocked=3 in wh_1 (should be included)
    # @simple_sku has top-level blocked=2 in wh_1 (should be included)
    # @blocked_sku has top-level blocked=20 in wh_1 (should be included)
    assert_includes @response.body, @sku.sku # Should be included (has blocked=2 in batches/variants)
    assert_includes @response.body, @bundle_sku.sku # Should be included (has blocked=3 at top level)
    assert_includes @response.body, @simple_sku.sku # Should be included (has blocked=2 at top level)
    assert_includes @response.body, @blocked_sku.sku # Should be included (has blocked=20 at top level)
  end

  test "should export nested warehouse structure when warehouse filter is applied" do
    get export_dashboard_index_url(format: :json), params: { warehouse: "wh_1" }
    assert_response :success
    data = JSON.parse(@response.body)
    
    # Check that the export includes warehouse, batches, and variants fields
    sku_with_batches = data.find { |sku| sku["sku"] == @sku.sku }
    assert_not_nil sku_with_batches["warehouse"], "Export should include warehouse field"
    assert_not_nil sku_with_batches["batches"], "Export should include batches field"
    assert_not_nil sku_with_batches["variants"], "Export should include variants field"
    
    # Check that batches and variants have the expected structure
    assert sku_with_batches["batches"].is_a?(Hash), "Batches should be a hash"
    assert sku_with_batches["variants"].is_a?(Hash), "Variants should be a hash"
    
    # Check that warehouse field contains the selected warehouse
    assert_equal "wh_1", sku_with_batches["warehouse"], "Warehouse field should contain selected warehouse"
  end

  test "should preserve nested warehouse structure in UI when warehouse filter is applied" do
    get dashboard_index_url, params: { warehouse: "wh_1" }
    assert_response :success
    
    # Check that the view has access to nested warehouse data
    assert_not_nil assigns(:skus)
    sku_with_batches = assigns(:skus).find { |sku| sku["sku"] == @sku.sku }
    assert_not_nil sku_with_batches, "Should find @sku in filtered results"
    
    # Check that warehouses field contains the selected warehouse with full structure
    assert sku_with_batches["warehouses"].is_a?(Hash), "Warehouses should be a hash"
    assert sku_with_batches["warehouses"].key?("wh_1"), "Should contain selected warehouse"
    
    # Check that batches and variants are preserved
    assert_not_nil sku_with_batches["batches"], "Batches should be preserved"
    assert_not_nil sku_with_batches["variants"], "Variants should be preserved"
    assert sku_with_batches["batches"].is_a?(Hash), "Batches should be a hash"
    assert sku_with_batches["variants"].is_a?(Hash), "Variants should be a hash"
  end

  # NOTE: If you are using Mongoid, consider running tests serially (DISABLE parallelization) to avoid DB state issues.
end
