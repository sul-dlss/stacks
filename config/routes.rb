Rails.application.routes.draw do
  druid_regex = /([a-z]{2})(\d{3})([a-z]{2})(\d{4})/i

  get '/object/:id' => 'object#show', as: :object
  get '/object/:id/version/:version_id', to: 'object#show'

  constraints id: druid_regex do
    scope format: false do  # Tell rails not to separate out the filename suffixes
      scope '/v2' do # versionable files
        get '/file/:id/version/:version_id/*file_name', to: 'file#show', as: :versioned_file
        options '/file/:id/version/:version_id/*file_name', to: 'file#options'
      end

      # File/auth routes without druid namespace
      get '/file/:id/*file_name' => 'file#show', as: :file
      options '/file/:id/*file_name', to: 'file#options'
      get '/file/auth/:id/*file_name' => 'webauth#login_file', as: :auth_file
      get '/file/auth/:id' => 'webauth#login_object', as: :auth_object

      # File/auth routes with druid namespace
      get '/file/druid::id/*file_name' => 'file#show'
      options '/file/druid::id/*file_name', to: 'file#options'
      get '/file/auth/druid::id/*file_name' => 'webauth#login_file'
      get '/file/auth/druid::id' => 'webauth#login_object'
    end
  end

  if Settings.features.streaming_media
    # stream file_name must include format extension, eg .../oo000oo0000.mp4/verify_token
    #  other dots do not need to be URL encoded (see media routing specs)
    constraints id: druid_regex, file_name: %r{[^/]+\.\w+} do
      get '/media/:id/:file_name/verify_token' => 'media#verify_token'
      get '/media/druid::id/:file_name/verify_token' => 'media#verify_token'
    end
  end

  root 'stacks#index'

  get '/auth/iiif' => 'webauth#login', as: :iiif_auth_api
  get '/auth/logout' => 'webauth#logout', as: :logout
  get '/image/iiif/token' => 'iiif/auth/v1/token#create', as: :iiif_token_api

  constraints id: druid_regex, file_name: %r{[^/]+}, size: %r{[^/]+} do
    get '/image/iiif/:id/:file_name', to: redirect('/image/iiif/%{id}/%{file_name}/info.json', status: 303), as: :iiif_base
    get '/image/iiif/:id/:file_name/:region/:size/:rotation/:quality.:format' => 'iiif#show', as: :iiif
    get '/image/iiif/:id/:file_name/info.json' => 'iiif#metadata', as: :iiif_metadata
    match '/image/iiif/:id/:file_name/info.json' => 'iiif#metadata_options', via: [:options]
    get '/image/iiif/auth/:id/:file_name/:region/:size/:rotation/:quality' => 'webauth#login_iiif', as: :auth_iiif

    get '/image/iiif/degraded/:id/:file_name', to: redirect('/image/iiif/degraded/%{identifier}/info.json', status: 303), as: :degraded_iiif_base, defaults: { degraded: true }
    get '/image/iiif/degraded/:id/:file_name/:region/:size/:rotation/:quality.:format' => 'iiif#show', as: :degraded_iiif, defaults: { degraded: true }
    get '/image/iiif/degraded/:id/:file_name/info.json' => 'iiif#metadata', as: :degraded_iiif_metadata, defaults: { degraded: true }
    match '/image/iiif/degraded/:id/:file_name/info.json' => 'iiif#metadata_options', via: [:options], defaults: { degraded: true }
    get '/image/iiif/auth/degraded/:id/:file_name/:region/:size/:rotation/:quality' => 'webauth#login_iiif', as: :degraded_auth_iiif, defaults: { degraded: true }
  end

  constraints identifier: %r{#{druid_regex}%(25)?2F[^/]+}, size: %r{[^/]+} do
    get '/image/iiif/:identifier', to: redirect('/image/iiif/%{identifier}/info.json', status: 303)
    get '/image/iiif/:identifier/:region/:size/:rotation/:quality.:format' => 'iiif#show'
    get '/image/iiif/:identifier/info.json' => 'iiif#metadata'
    match '/image/iiif/:identifier/info.json' => 'iiif#metadata_options', via: [:options]
  end

  # As of Aug 2024, the legacy service was still used by Bassi Verati/FRDA
  # It's also likely used by other applications too.
  # The LegacyImageService is just a facade that redirects to the appropriate IIIF URI
  constraints id: druid_regex, file_name: %r{[^/]+}, format: %r{(jpg|png|gif|jp2)}, size: %r{(#{Settings.legacy.sizes.join('|')})} do
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

  # IIIF Auth V2
  get '/iiif/auth/v2/token' => 'iiif/auth/v2/token#create'
  get '/iiif/auth/v2/probe' => 'iiif/auth/v2/probe_service#show'
  options '/iiif/auth/v2/probe' => 'iiif/auth/v2/probe_service#options_pre_flight'

end
