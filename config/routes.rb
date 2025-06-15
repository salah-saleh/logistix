Rails.application.routes.draw do
  root "dashboard#index"
  
  get "dashboard", to: "dashboard#index", as: :dashboard_index
  get "dashboard/show/:sku", to: "dashboard#show", as: :show_dashboard
  get "dashboard/export", to: "dashboard#export", as: :export_dashboard_index
  get "dashboard/download/:sku", to: "dashboard#download", as: :download_dashboard
  get "dashboard/download_history/:sku", to: "dashboard#download_history", as: :download_history_dashboard
  post "dashboard/import", to: "dashboard#import", as: :import_dashboard_index

  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
