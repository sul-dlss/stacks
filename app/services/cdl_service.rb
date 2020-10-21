# frozen_string_literal: true

# Produces iiif services for checking items out using CDL
class CdlService
  # helper method to create a new auth service
  # @param context [IiifController] a controller context used to make url helpers
  def self.to_iiif(context, current_image)
    new(context, current_image).to_iiif
  end

  # @param context [IiifController] a controller context used to make url helpers
  def initialize(context, current_image)
    @context = context
    @current_image = current_image
  end

  def to_iiif
    {
      '@context' => 'http://iiif.io/api/auth/1/context.json',
      '@id' => cdl_checkout_iiif_auth_api_url(id),
      'profile' => 'http://iiif.io/api/auth/1/login',
      'label' => 'Available for checkout',
      'header' => 'SUNetID required: This item is available to Stanford affiliates only. Download is prohibited.',
      'confirmLabel' => 'Check out',
      'failureHeader' => 'Unable to authenticate',
      'failureDescription' => 'The authentication service cannot be reached.',
      'service' => [
        {
          '@id' => cdl_iiif_token_api_url(id),
          'profile' => 'http://iiif.io/api/auth/1/token'
        },
        {
          '@id' => cdl_checkin_iiif_auth_api_url(id),
          'profile' => 'http://iiif.io/api/auth/1/logout',
          'label' => 'Check in early'
        },
        {
          '@id' => cdl_info_iiif_auth_api_url(id),
          'profile' => 'http://iiif.io/api/auth/1/info'
        },
        {
          '@id' => cdl_renew_iiif_auth_api_url(id),
          'profile' => 'http://iiif.io/api/auth/1/renew'
        }
      ]
    }
  end

  delegate :cdl_checkout_iiif_auth_api_url, :cdl_checkin_iiif_auth_api_url,
           :cdl_iiif_token_api_url, :cdl_info_iiif_auth_api_url, :cdl_renew_iiif_auth_api_url, to: :url_helpers

  def url_helpers
    @context
  end

  def id
    @current_image.id
  end
end
