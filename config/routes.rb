Rails.application.routes.draw do
  root 'landing#index'
  
  # Authentication routes
  get '/login', to: 'sessions#new', as: 'login'
  post '/login', to: 'sessions#create'
  delete '/logout', to: 'sessions#destroy', as: 'logout'
  
  get '/signup', to: 'registrations#new', as: 'signup'
  post '/signup', to: 'registrations#create'
  
  get '/password/reset', to: 'passwords#new', as: 'new_password'
  post '/password/reset', to: 'passwords#create'
  get '/password/reset/:id/edit', to: 'passwords#edit', as: 'edit_password'
  patch '/password/reset/:id', to: 'passwords#update'
  
  # Protected routes (require authentication)
  get '/dashboard', to: 'dashboard#index', as: 'dashboard_index'
  get '/dashboard/export', to: 'dashboard#export', as: 'export_dashboard_index'
  get '/dashboard/export_excel', to: 'dashboard#export_excel', as: 'export_excel_dashboard_index'
  get '/dashboard/export_pdf', to: 'dashboard#export_pdf', as: 'export_pdf_dashboard_index'
  
  resources :portfolios do
    collection do
      get :chart_data
    end
  end
  
  resources :savings_accounts do
    collection do
      get :chart_data
      post :reorder
    end
    member do
      post :bulk_update_snapshots
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
  
  resources :retirement_scenarios, only: [:index, :create, :edit, :update, :destroy] do
    collection do
      post :calculate
      get :chart_data
      get :withdrawal_data
    end
    member do
      post :set_active
    end
  end
  
  resources :insurance_policies
  
  resources :tax_scenarios, only: [:index, :create, :edit, :update, :destroy]
  
  resources :settings, only: [:index, :update] do
    collection do
      post :export_data
      get :download_data_file
      post :update_password
      post :update_account
      delete :destroy_account
    end
  end
end
