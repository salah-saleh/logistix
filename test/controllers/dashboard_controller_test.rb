require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @test_data = [
      {
        "sku" => "TEST001",
        "is_batch" => true,
        "is_bundle" => false,
        "has_variants" => true,
        "quantity_on_shelf" => 10,
        "quantity_sellable" => 8,
        "quantity_reserved_for_orders" => 2,
        "quantity_blocked_by_merchant" => 0,
        "state" => "active",
        "last_update" => "20/03/2024 10:00 UTC",
        "warehouses" => {
          "wh_1" => {
            "quantity_on_shelf" => 5,
            "quantity_sellable" => 4,
            "quantity_reserved_for_orders" => 1,
            "quantity_blocked_by_merchant" => 0,
            "last_update" => "20/03/2024 10:00 UTC"
          },
          "wh_2" => {
            "quantity_on_shelf" => 5,
            "quantity_sellable" => 4,
            "quantity_reserved_for_orders" => 1,
            "quantity_blocked_by_merchant" => 0,
            "last_update" => "20/03/2024 10:00 UTC"
          }
        }
      },
      {
        "sku" => "TEST002",
        "is_batch" => false,
        "is_bundle" => true,
        "has_variants" => false,
        "quantity_on_shelf" => 20,
        "quantity_sellable" => 15,
        "quantity_reserved_for_orders" => 5,
        "quantity_blocked_by_merchant" => 0,
        "state" => "inactive",
        "last_update" => "20/03/2024 10:00 UTC",
        "warehouses" => {
          "wh_1" => {
            "quantity_on_shelf" => 20,
            "quantity_sellable" => 15,
            "quantity_reserved_for_orders" => 5,
            "quantity_blocked_by_merchant" => 0,
            "last_update" => "20/03/2024 10:00 UTC"
          }
        }
      }
    ]
  end

  test "should get index" do
    get dashboard_index_url
    assert_response :success
  end

  test "should export JSON" do
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)

    get export_dashboard_index_url(format: :json)
    assert_response :success
    assert_equal "application/json", @response.content_type.split(";").first
    exported_data = JSON.parse(@response.body)
    assert_equal @test_data.first["sku"], exported_data.first["sku"]
  end

  test "should export CSV" do
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)

    get export_dashboard_index_url(format: :csv)
    assert_response :success
    assert_equal "text/csv", @response.content_type
    assert_match(/TEST001/, @response.body)
  end

  test "should import JSON with overwrite" do
    initial_data = [{
      "sku" => "EXISTING001",
      "is_batch" => false,
      "is_bundle" => false,
      "quantity_on_shelf" => 5,
      "quantity_sellable" => 5,
      "quantity_reserved_for_orders" => 0,
      "quantity_blocked_by_merchant" => 0,
      "state" => "active",
      "last_update" => "2024-03-20 10:00:00 UTC",
      "warehouses" => {}
    }]
    File.write(Rails.root.join("db", "mock_sku_data.json"), initial_data.to_json)

    temp_file = Tempfile.new(["test_import", ".json"])
    temp_file.write(@test_data.to_json)
    temp_file.rewind

    post import_dashboard_index_url, params: {
      file: Rack::Test::UploadedFile.new(temp_file.path, "application/json"),
      overwrite: "1"
    }

    assert_redirected_to dashboard_index_url
    assert_equal "Data imported successfully (overwritten).", flash[:notice]

    final_data = JSON.parse(File.read(Rails.root.join("db", "mock_sku_data.json")))
    assert_equal 2, final_data.length
    assert_equal "TEST001", final_data.first["sku"]
  end

  test "should import JSON without overwrite" do
    initial_data = [{
      "sku" => "EXISTING001",
      "is_batch" => false,
      "is_bundle" => false,
      "quantity_on_shelf" => 5,
      "quantity_sellable" => 5,
      "quantity_reserved_for_orders" => 0,
      "quantity_blocked_by_merchant" => 0,
      "state" => "active",
      "last_update" => "2024-03-20 10:00:00 UTC",
      "warehouses" => {}
    }]
    File.write(Rails.root.join("db", "mock_sku_data.json"), initial_data.to_json)

    temp_file = Tempfile.new(["test_import", ".json"])
    temp_file.write(@test_data.to_json)
    temp_file.rewind

    post import_dashboard_index_url, params: {
      file: Rack::Test::UploadedFile.new(temp_file.path, "application/json"),
      overwrite: "0"
    }

    assert_redirected_to dashboard_index_url
    assert_equal "Data imported successfully (partial update).", flash[:notice]

    final_data = JSON.parse(File.read(Rails.root.join("db", "mock_sku_data.json")))
    assert_equal 3, final_data.length
    assert final_data.any? { |sku| sku["sku"] == "EXISTING001" }
    assert final_data.any? { |sku| sku["sku"] == "TEST001" }
  end

  test "should handle invalid JSON import" do
    temp_file = Tempfile.new(["test_import", ".json"])
    temp_file.write("invalid json")
    temp_file.rewind

    post import_dashboard_index_url, params: {
      file: Rack::Test::UploadedFile.new(temp_file.path, "application/json"),
      overwrite: "1"
    }

    assert_redirected_to dashboard_index_url
    assert_match(/Error importing data/, flash[:error])
  end

  test "should handle missing file in import" do
    post import_dashboard_index_url
    assert_redirected_to dashboard_index_url
    assert_equal "No file uploaded.", flash[:error]
  end

  test "should filter by warehouse" do
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)
    
    get dashboard_index_url, params: { warehouse: "wh_1" }
    assert_response :success
    assert_select "td", "5" # Should show warehouse-specific quantity
  end

  test "should filter by quantity ranges" do
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)
    
    get dashboard_index_url, params: {
      min_on_shelf: 5,
      max_on_shelf: 15,
      min_sellable: 5,
      max_sellable: 10
    }
    assert_response :success
    assert_select "td", "TEST001"
  end

  test "should filter by type and state" do
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)
    
    get dashboard_index_url, params: {
      type: "batch",
      state: "active"
    }
    assert_response :success
    assert_select "td", "Batch"
    assert_select "td", "Active"
  end

  test "should filter by variants" do
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)
    
    get dashboard_index_url, params: { has_variants: "true" }
    assert_response :success
    assert_select "td", "Yes"
  end

  test "should paginate results" do
    # Create multiple test records
    test_data = (1..15).map do |i|
      @test_data.first.merge("sku" => "TEST#{i.to_s.rjust(3, '0')}")
    end
    File.write(Rails.root.join("db", "mock_sku_data.json"), test_data.to_json)
    
    get dashboard_index_url, params: { page: 2 }
    assert_response :success
    assert_select "nav[aria-label='Pagination']"
    assert_select "a[href*='page=2']"
  end

  test "should import CSV" do
    temp_file = Tempfile.new(["test_import", ".csv"])
    temp_file.write("SKU,Type,Variants,State,Total On Shelf,Total Sellable,Total Reserved,Total Blocked,Last Update\n")
    temp_file.write("TEST001,batch,No,active,10,8,2,0,2024-03-20 10:00:00 UTC\n")
    temp_file.rewind

    post import_dashboard_index_url, params: {
      file: Rack::Test::UploadedFile.new(temp_file.path, "text/csv"),
      overwrite: "1"
    }

    assert_redirected_to dashboard_index_url
    assert_equal "Data imported successfully (overwritten).", flash[:notice]
  end

  test "should download current data" do
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)
    
    get download_dashboard_url(sku: "TEST001", format: :json)
    assert_response :success
    assert_equal "application/json", @response.content_type.split(";").first
    
    get download_dashboard_url(sku: "TEST001", format: :csv)
    assert_response :success
    assert_equal "text/csv", @response.content_type
  end

  test "should download historical data" do
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)
    
    get download_history_dashboard_url(sku: "TEST001", format: :json)
    assert_response :success
    assert_equal "application/json", @response.content_type.split(";").first
    
    get download_history_dashboard_url(sku: "TEST001", format: :csv)
    assert_response :success
    assert_equal "text/csv", @response.content_type
  end

  test "should handle non-existent SKU in download" do
    get download_dashboard_url(sku: "NONEXISTENT", format: :json)
    assert_response :not_found
  end

  test "should handle non-existent SKU in history download" do
    get download_history_dashboard_url(sku: "NONEXISTENT", format: :json)
    assert_response :not_found
  end

  test "should disable import in non-development environment" do
    original_env = Rails.env
    Rails.env = ActiveSupport::EnvironmentInquirer.new("production")
    
    get dashboard_index_url
    assert_response :success
    assert_select "input[type='file'][disabled]"
    assert_select "input[type='checkbox'][disabled]"
    assert_select "button[disabled]"
  ensure
    Rails.env = original_env
  end

  test "should sort by different columns" do
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)
    
    # Test sorting by SKU
    get dashboard_index_url, params: { sort_by: "sku", sort_order: "asc" }
    assert_response :success
    
    # Test sorting by quantity
    get dashboard_index_url, params: { sort_by: "quantity_on_shelf", sort_order: "desc" }
    assert_response :success
    
    # Test sorting by last update
    get dashboard_index_url, params: { sort_by: "last_update", sort_order: "desc" }
    assert_response :success
  end

  test "should combine multiple filters" do
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)
    
    get dashboard_index_url, params: {
      type: "batch",
      state: "active",
      warehouse: "wh_1",
      min_on_shelf: 5,
      has_variants: "true"
    }
    assert_response :success
    assert_select "td", "TEST001"
  end
end
