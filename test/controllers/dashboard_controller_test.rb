require "test_helper"

class DashboardControllerTest < ActionDispatch::IntegrationTest
  setup do
    @test_data = [
      {
        "sku" => "TEST001",
        "is_batch" => true,
        "is_bundle" => false,
        "quantity_on_shelf" => 10,
        "quantity_sellable" => 8,
        "quantity_reserved_for_orders" => 2,
        "quantity_blocked_by_merchant" => 0,
        "state" => "active",
        "last_update" => "2024-03-20 10:00:00 UTC",
        "warehouses" => {
          "wh_1" => {
            "quantity_on_shelf" => 5,
            "quantity_sellable" => 4,
            "quantity_reserved_for_orders" => 1,
            "quantity_blocked_by_merchant" => 0,
            "last_update" => "2024-03-20 10:00:00 UTC"
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
    # Write test data to file
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)

    get export_dashboard_index_url(format: :json)
    assert_response :success
    assert_equal "application/json", @response.content_type
    exported_data = JSON.parse(@response.body)
    assert_equal @test_data.first["sku"], exported_data.first["sku"]
  end

  test "should export CSV" do
    # Write test data to file
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)

    get export_dashboard_index_url(format: :csv)
    assert_response :success
    assert_equal "text/csv", @response.content_type
    assert_match(/TEST001/, @response.body)
  end

  test "should import JSON with overwrite" do
    # Create a temporary JSON file for upload
    temp_file = Tempfile.new(["test_import", ".json"])
    temp_file.write(@test_data.to_json)
    temp_file.rewind

    assert_difference -> { JSON.parse(File.read(Rails.root.join("db", "mock_sku_data.json"))).length } do
      post import_dashboard_index_url, params: {
        file: Rack::Test::UploadedFile.new(temp_file.path, "application/json"),
        overwrite: "1"
      }
    end

    assert_redirected_to dashboard_index_url
    assert_equal "Data imported successfully (overwritten).", flash[:notice]
  end

  test "should import JSON without overwrite" do
    # Create initial data
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

    # Create a temporary JSON file for upload
    temp_file = Tempfile.new(["test_import", ".json"])
    temp_file.write(@test_data.to_json)
    temp_file.rewind

    post import_dashboard_index_url, params: {
      file: Rack::Test::UploadedFile.new(temp_file.path, "application/json"),
      overwrite: "0"
    }

    assert_redirected_to dashboard_index_url
    assert_equal "Data imported successfully (partial update).", flash[:notice]

    # Verify both SKUs exist
    final_data = JSON.parse(File.read(Rails.root.join("db", "mock_sku_data.json")))
    assert_equal 2, final_data.length
    assert final_data.any? { |sku| sku["sku"] == "EXISTING001" }
    assert final_data.any? { |sku| sku["sku"] == "TEST001" }
  end

  test "should handle invalid JSON import" do
    # Create a temporary file with invalid JSON
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

  test "should filter and sort data" do
    # Write test data to file
    File.write(Rails.root.join("db", "mock_sku_data.json"), @test_data.to_json)

    get dashboard_index_url, params: {
      sku: "TEST",
      sort_by: "sku",
      sort_dir: "asc"
    }
    assert_response :success
    assert_select "td", "TEST001"
  end
end
