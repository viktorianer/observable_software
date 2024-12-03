Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  mount SolidErrors::Engine, at: "/solid_errors"
  mount MissionControl::Jobs::Engine, at: "/jobs"

  resources :patterns, only: [ :new, :create, :show, :edit, :update ] do
    member do
      get :update_progress
      get :download
      get :download_pdf
    end
  end
  root "patterns#new"
end
