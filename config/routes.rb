Rails.application.routes.draw do
  constraints file_name: %r{[^/]+} do
    get '/file/:id/:file_name' => 'file#show', as: :file
    get '/file/app/:id/:file_name' => 'webauth#login_file'
    get '/file/auth/:id/:file_name' => 'webauth#login_file', as: :auth_file
  end

  constraints file_name: %r{[^/][\w-]+} do
    get '/media/:id/:file_name' => 'media#download', as: :media
    get '/media/auth/:id/:file_name' => 'webauth#login_media_download', as: :auth_media_download
  end

  # stream file_name must include format extension, eg .../oo000oo0000.mp4/stream
  constraints file_name: %r{[^/][\w\.-]+} do
    get '/media/:id/:file_name/stream' => 'media#stream', as: :media_stream
    get '/media/auth/:id/:file_name/stream' => 'webauth#login_media_stream', as: :auth_media_stream
  end

  get '/image/iiif' => 'stacks#iiif'
  root 'stacks#index'

  get '/auth/iiif' => 'webauth#login', as: :iiif_auth_api
  get '/image/iiif/token' => 'iiif_token#create', as: :iiif_token_api

  constraints identifier: %r{[^/]+}, size: %r{[^/]+} do
    get '/image/iiif/:identifier' => 'iiif#show', as: :iiif_base
    get '/image/iiif/:identifier/:region/:size/:rotation/:quality' => 'iiif#show', as: :iiif
    get '/image/iiif/:identifier/info.json' => 'iiif#metadata', as: :iiif_metadata
    match '/image/iiif/:identifier/info.json' => 'iiif#metadata_options', via: [:options]
    get '/image/iiif/app/:identifier/:region/:size/:rotation/:quality' => 'webauth#login_iiif'
    get '/image/iiif/auth/:identifier/:region/:size/:rotation/:quality' => 'webauth#login_iiif', as: :auth_iiif
  end

  constraints file_name: %r{[^/]+}, format: %r{(jpg|png|gif|jp2)}, size: %r{(#{Settings.legacy.sizes.join('|')})} do
    get '/image/:id/(:file_name)_:size(.:format)' => 'legacy_image_service#show'
    get '/image/:id/:file_name.:format' => 'legacy_image_service#show'
    get '/image/:id/:file_name' => 'legacy_image_service#show'
    get '/image/app/:id/(:file_name)_:size(.:format)' => 'legacy_image_service#show'
    get '/image/app/:id/:file_name.:format' => 'legacy_image_service#show'
    get '/image/app/:id/:file_name' => 'legacy_image_service#show'

    get '/image/auth/:id/(:file_name)_:size(.:format)' => 'legacy_image_service#show'
    get '/image/auth/:id/:file_name.:format' => 'legacy_image_service#show'
    get '/image/auth/:id/:file_name' => 'legacy_image_service#show'
  end
end
