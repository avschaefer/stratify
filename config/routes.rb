Rails.application.routes.draw do
  # Devise routes are commented out for UI testing - authentication is disabled
  # devise_for :users
  
  # Catch-all routes for Devise paths (redirect to dashboard since auth is disabled)
  get '/users/sign_in', to: redirect('/')
  get '/users/sign_up', to: redirect('/')
  get '/users/sign_out', to: redirect('/')
  get '/users/password/new', to: redirect('/')
  get '/users/password/edit', to: redirect('/')
  get '/users/confirmation/new', to: redirect('/')
  delete '/users/sign_out', to: redirect('/')
  post '/users/sign_in', to: redirect('/')
  post '/users/sign_up', to: redirect('/')
  
  root 'dashboard#index'
  
  resources :dashboard, only: [:index] do
    collection do
      get :export
    end
  end
  
  resources :portfolios do
    collection do
      get :chart_data
    end
  end
  
  resources :savings_accounts do
    collection do
      get :chart_data
    end
    resources :monthly_snapshots, only: [:create, :update, :destroy], controller: 'monthly_snapshots'
  end
  
  resources :expenses do
    resources :monthly_snapshots, only: [:create, :update, :destroy], controller: 'monthly_snapshots'
  end
  
  resources :loans do
    collection do
      post :calculate
    end
  end
  
  resources :retirement_scenarios, only: [:index, :create, :update, :destroy] do
    collection do
      post :calculate
    end
    member do
      post :set_active
    end
  end
  
  resources :insurance_policies do
    collection do
      post :calculate
    end
  end
  
  resources :tax_scenarios, only: [:index, :create, :update, :destroy] do
    collection do
      post :calculate
    end
  end
  
  resources :settings, only: [:index, :update]
end
