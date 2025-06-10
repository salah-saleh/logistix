class DashboardController < ApplicationController
  def index
    file_path = Rails.root.join("db", "mock_sku_data.json")
    @skus = JSON.parse(File.read(file_path))
  end
end
