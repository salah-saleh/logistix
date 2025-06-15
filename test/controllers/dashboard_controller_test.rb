require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    # Clean up the database before each test
    Mongoid.purge!
    
    # Create test data
    @sku = Sku.create!(
      sku: "TEST-SKU-001",
      is_batch: false,
      is_bundle: false,
      has_variants: false,
      quantity_on_shelf: 100,
      quantity_sellable: 90,
      quantity_reserved_for_orders: 10,
      quantity_blocked_by_merchant: 0,
      warehouses: {
        "main" => { "quantity" => 50 },
        "secondary" => { "quantity" => 50 }
      },
      state: "active",
      last_update: Time.current
    )

    # Force persistence
    @sku.save!
    
    # Verify the SKU was created
    assert_not_nil @sku, "Test SKU object is nil"
    assert_not_nil @sku.id, "Test SKU has no ID"
    assert_equal "TEST-SKU-001", @sku.sku, "Test SKU has wrong SKU value"
    
    # Verify the SKU exists in the database
    found_sku = Sku.find_by(sku: @sku.sku)
    assert_not_nil found_sku, "Test SKU was not found in database"
    assert_equal @sku.id, found_sku.id, "Found SKU has different ID"
    
    # Log the SKU details for debugging
    Rails.logger.debug "Created test SKU: #{@sku.attributes.inspect}"
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

  test "should filter by warehouse" do
    get dashboard_index_url, params: { warehouse: "main" }
    assert_response :success
  end

  test "should filter by state" do
    get dashboard_index_url, params: { state: "active" }
    assert_response :success
  end

  test "should filter by type" do
    get dashboard_index_url, params: { type: "batch" }
    assert_response :success
  end

  test "should filter by has variants" do
    get dashboard_index_url, params: { has_variants: "true" }
    assert_response :success
  end

  test "should filter by quantity ranges" do
    get dashboard_index_url, params: {
      min_on_shelf: 50,
      max_on_shelf: 150,
      min_sellable: 40,
      max_sellable: 140
    }
    assert_response :success
  end

  test "should sort by different fields" do
    get dashboard_index_url, params: { sort_by: "quantity_on_shelf", sort_order: "desc" }
    assert_response :success
  end

  test "should handle import with overwrite" do
    file = fixture_file_upload("test/fixtures/files/sku_data.json", "application/json")
    post import_dashboard_index_url, params: { file: file, overwrite: "1" }
    assert_redirected_to dashboard_index_url
  end

  test "should handle import without overwrite" do
    file = fixture_file_upload("test/fixtures/files/sku_data.json", "application/json")
    post import_dashboard_index_url, params: { file: file }
    assert_redirected_to dashboard_index_url
  end

  test "should handle invalid import file" do
    file = fixture_file_upload("test/fixtures/files/invalid.json", "application/json")
    post import_dashboard_index_url, params: { file: file }
    assert_redirected_to dashboard_index_url
  end

  test "should handle missing import file" do
    post import_dashboard_index_url
    assert_redirected_to dashboard_index_url
  end
end
