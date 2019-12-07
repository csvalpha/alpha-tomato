Rails.application.routes.draw do
  devise_for :users, controllers: { omniauth_callbacks: 'callbacks' }

  resources :activities, only: %i[index show create update destroy] do
    member do
      get :order_screen
      post :lock
    end
  end

  resources :orders, only: %i[index create update]
  resources :price_lists, only: %i[index create update]

  resources :users, only: %i[index show create] do
    collection do
      get :refresh_user_list
      post :search
    end
    member do
      get :activities
    end
  end

  resources :products, only: %i[create update], defaults: { format: :json }
  resources :credit_mutations, only: %i[index create]
  resources :zatladder, only: %i[index]

  devise_scope :user do
    delete 'sign_out', to: 'devise/sessions#destroy', as: :destroy_user_session
  end

  # Sidekiq dashboard
  require 'sidekiq/web'
  # See https://github.com/mperham/sidekiq/wiki/Monitoring#forbidden
  Sidekiq::Web.set :session_secret, Rails.application.credentials[:secret_key_base]

  authenticate :user, ->(u) { u.treasurer? } do
    mount Sidekiq::Web => '/sidekiq'
  end

  root to: 'index#index'

  get '/403', to: 'errors#forbidden'
  get '/404', to: 'errors#not_found'
  get '/422', to: 'errors#unacceptable'
  get '/500', to: 'errors#internal_server_error'
end
