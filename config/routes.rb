Rails.application.routes.draw do
  constraints file_name: %r{[^/]+} do
    get '/file/:id/:file_name' => 'file#show', as: :file
    get '/file/app/:id/:file_name' => 'webauth#login_file'
    get '/file/auth/:id/:file_name' => 'webauth#login_file', as: :auth_file
  end

  if Settings.features.streaming_media
    # stream file_name must include format extension, eg .../oo000oo0000.mp4/verify_token
    #  other dots do not need to be URL encoded (see media routing specs)
    constraints file_name: %r{[^/]+\.\w+} do
      get '/media/:id/:file_name/verify_token' => 'media#verify_token'
      get '/media/:id/:file_name/auth_check' => 'media#auth_check'
    end
  end

  get '/image/iiif' => 'stacks#iiif'
  root 'stacks#index'

  get '/auth/iiif' => 'webauth#login', as: :iiif_auth_api
  get '/auth/logout' => 'webauth#logout', as: :logout
  get '/image/iiif/token' => 'iiif_token#create', as: :iiif_token_api

  constraints identifier: %r{[^/]+}, size: %r{[^/]+} do
    get '/image/iiif/:identifier', to: redirect('/image/iiif/%{identifier}/info.json', status: 303), as: :iiif_base
    get '/image/iiif/:identifier/:region/:size/:rotation/:quality' => 'iiif#show', as: :iiif
    get '/image/iiif/:identifier/info.json' => 'iiif#metadata', as: :iiif_metadata
    match '/image/iiif/:identifier/info.json' => 'iiif#metadata_options', via: [:options]
    get '/image/iiif/app/:identifier/:region/:size/:rotation/:quality' => 'webauth#login_iiif'
    get '/image/iiif/auth/:identifier/:region/:size/:rotation/:quality' => 'webauth#login_iiif', as: :auth_iiif
  end

  # As of Sept 2017, the legacy service was still used by Revs and Bassi Verati/FRDA
  # It's also likely used by other applications too.
  # The LegacyImageService is just a facade that redirects to the appropriate IIIF URI
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
