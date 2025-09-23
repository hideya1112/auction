Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # ユーザー認証
  get '/login', to: 'users#login', as: :user_login
  post '/login', to: 'users#authenticate', as: :user_authenticate
  delete '/logout', to: 'users#logout', as: :user_logout
  get '/logout', to: 'users#logout', as: :user_logout_get

  resources :auctions, only: [:show, :update]
  
  # 参加者用画面
  get 'auctions/:id/participant', to: 'auctions#participant', as: :participant_auction
  # モニター用画面
  get 'auctions/:id/monitor', to: 'auctions#monitor', as: :monitor_auction
  
  # 管理者用画面
  namespace :admin do
    get '/', to: 'dashboard#index'
    get '/login', to: 'sessions#new'
    post '/login', to: 'sessions#create'
    delete '/logout', to: 'sessions#destroy'
    
    resources :items
    resources :auctions do
      member do
        patch :hammer_price
        patch :rollback_bid
        patch :next_item
      end
    end
    get '/bid_logs', to: 'bid_logs#index'
  end
  
  root 'auctions#participant', defaults: { id: 1 }  # ルートパスは参加者用画面を表示
  # Render dynamic PWA files from app/views/pwa/* (remember to check manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  # root "posts#index"
end
