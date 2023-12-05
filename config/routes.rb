Rails.application.routes.draw do
  druid_regex = /([a-z]{2})(\d{3})([a-z]{2})(\d{4})/i

  get '/object/:id' => 'object#show', as: :object

  constraints id: druid_regex do
    get '/file/:id/*file_name' => 'file#show', format: false, as: :file
    options '/file/:id/*file_name', to: 'file#options', format: false
    get '/file/app/:id/*file_name' => 'webauth#login_file', format: false
    get '/file/auth/:id/*file_name' => 'webauth#login_file', format: false, as: :auth_file
    get '/file/auth/:id' => 'webauth#login_object', format: false, as: :auth_object

    get '/file/druid::id/*file_name' => 'file#show', format: false
    options '/file/druid::id/*file_name', to: 'file#options', format: false
    get '/file/app/druid::id/*file_name' => 'webauth#login_file', format: false
    get '/file/auth/druid::id/*file_name' => 'webauth#login_file', format: false
    get '/file/auth/druid::id' => 'webauth#login_object', format: false
    get '/file/:id/:file_name/auth_check' => 'file#auth_check'
  end

  if Settings.features.streaming_media
    # stream file_name must include format extension, eg .../oo000oo0000.mp4/verify_token
    #  other dots do not need to be URL encoded (see media routing specs)
    constraints id: druid_regex, file_name: %r{[^/]+\.\w+} do
      get '/media/:id/:file_name/verify_token' => 'media#verify_token'
      get '/media/:id/:file_name/auth_check' => 'media#auth_check'

      get '/media/druid::id/:file_name/verify_token' => 'media#verify_token'
      get '/media/druid::id/:file_name/auth_check' => 'media#auth_check'
    end
  end

  root 'stacks#index'

  get '/auth/iiif' => 'webauth#login', as: :iiif_auth_api
  get '/auth/iiif/cdl/:id/checkout' => 'cdl#create', as: :cdl_checkout_iiif_auth_api
  get '/auth/iiif/cdl/:id/checkin' => 'cdl#delete', as: :cdl_checkin_iiif_auth_api
  get '/auth/iiif/cdl/:id/renew' => 'cdl#renew', as: :cdl_renew_iiif_auth_api
  get '/auth/iiif/cdl/:id/checkout/success' => 'cdl#create_success', as: :cdl_checkout_success_iiif_auth_api
  get '/auth/iiif/cdl/:id/checkin/success' => 'cdl#delete_success', as: :cdl_checkin_success_iiif_auth_api
  get '/auth/iiif/cdl/:id/renew/success' => 'cdl#renew_success', as: :cdl_renew_success_iiif_auth_api
  get '/cdl/:id' => 'cdl#show', as: :cdl_info_iiif_auth_api
  match '/cdl/:id' => 'cdl#show_options', via: [:options]
  get '/auth/logout' => 'webauth#logout', as: :logout
  get '/image/iiif/token' => 'iiif_token#create', as: :iiif_token_api
  get '/image/iiif/token/:id' => 'iiif_token#create_for_item', as: :cdl_iiif_token_api

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

  # As of Sept 2017, the legacy service was still used by Revs and Bassi Verati/FRDA
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
end
