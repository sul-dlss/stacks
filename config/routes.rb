Rails.application.routes.draw do
  # The priority is based upon order of creation: first created -> highest priority.
  # See how all your routes lay out with "rake routes".

  # You can have the root of your site routed with "root"
  # root 'welcome#index'

  # Example of regular route:
  #   get 'products/:id' => 'catalog#view'

  # Example of named route that can be invoked with purchase_url(id: product.id)
  #   get 'products/:id/purchase' => 'catalog#purchase', as: :purchase

  # Example resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Example resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Example resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Example resource route with more complex sub-resources:
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', on: :collection
  #     end
  #   end

  # Example resource route with concerns:
  #   concern :toggleable do
  #     post 'toggle'
  #   end
  #   resources :posts, concerns: :toggleable
  #   resources :photos, concerns: :toggleable

  # Example resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  constraints file_name: %r{[^/]+} do
    get '/file/:id/:file_name' => 'file#show', as: :file
    get '/file/:id/:file_name' => 'file#show'
    get '/file/auth/:id/:file_name' => 'webauth#file_login'
  end

  constraints identifier: %r{[^/]+}, size: %r{[^/]+} do
    get '/image/iiif/:identifier' => 'iiif#show', as: :iiif_base
    get '/image/iiif/:identifier/:region/:size/:rotation/:quality' => 'iiif#show', as: :iiif
    get '/image/iiif/:identifier/info.json' => 'iiif#metadata', as: :iiif_metadata
    get '/image/iiif/auth/:identifier' => 'webauth#iiif_login'
    get '/image/iiif/auth/:identifier/:region/:size/:rotation/:quality' => 'webauth#iiif_login'
    get '/image/iiif/auth/:identifier/info.json' => 'webauth#iiif_login'
  end

  get '/image/:id/:file_name' => 'legacy_image_service#show'
  get '/image/app/:id/:file_name' => 'legacy_image_service#show'
  get '/image/auth/:id/:file_name' => 'legacy_image_service#show'
end
