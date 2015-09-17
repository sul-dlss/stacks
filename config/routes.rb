Rails.application.routes.draw do
  constraints file_name: %r{[^/]+} do
    get '/file/:id/:file_name' => 'file#show', as: :file
    get '/file/app/:id/:file_name' => 'webauth#login_file'
    get '/file/auth/:id/:file_name' => 'webauth#login_file', as: :auth_file
  end

  get '/image/iiif' => 'stacks#iiif'
  root 'stacks#index'

  constraints identifier: %r{[^/]+}, size: %r{[^/]+} do
    get '/image/iiif/:identifier' => 'iiif#show', as: :iiif_base
    get '/image/iiif/:identifier/:region/:size/:rotation/:quality' => 'iiif#show', as: :iiif
    get '/image/iiif/:identifier/info.json' => 'iiif#metadata', as: :iiif_metadata
    get '/image/iiif/app/:identifier/:region/:size/:rotation/:quality' => 'webauth#login_iiif'
    get '/image/iiif/auth/:identifier/:region/:size/:rotation/:quality' => 'webauth#login_iiif', as: :auth_iiif
  end

  SIZE_CATEGORIES = %w(square thumb small medium large xlarge full)
  constraints file_name: %r{[^/]+}, format: %r{(jpg|png|gif|jp2)}, size: %r{(#{SIZE_CATEGORIES.join('|')})} do
    get '/image/:id/(:file_name)_:size(.:format)' => 'legacy_image_service#show'
    get '/image/:id/:file_name.:format' => 'legacy_image_service#show'
    get '/image/:id/:file_name' => 'legacy_image_service#show'
    get '/image/app/:id/:file_name.:format' => 'legacy_image_service#show'
    get '/image/auth/:id/:file_name.:format' => 'legacy_image_service#show'
  end
end
