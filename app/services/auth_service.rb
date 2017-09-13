# frozen_string_literal: true

# Produces iiif services for authenticating
class AuthService
  # helper method to create a new auth service
  # @param context [IiifController] a controller context used to make url helpers
  def self.to_iiif(context)
    new(context).to_iiif
  end

  # @param context [IiifController] a controller context used to make url helpers
  def initialize(context)
    @context = context
  end

  def to_iiif
    {
      '@context' => 'http://iiif.io/api/auth/1/context.json',
      '@id' => iiif_auth_api_url,
      'profile' => 'http://iiif.io/api/auth/1/login',
      'label' => 'Log in to access all available features.',
      'confirmLabel' => 'Login',
      'failureHeader' => 'Unable to authenticate',
      'failureDescription' => 'The authentication service cannot be reached'\
        '. If your browser is configured to block pop-up windows, try allow'\
        'ing pop-up windows for this site before attempting to log in again.',
      'service' => [
        {
          '@id' => iiif_token_api_url,
          'profile' => 'http://iiif.io/api/auth/1/token'
        },
        {
          '@id' => logout_url,
          'profile' => 'http://iiif.io/api/auth/1/logout',
          'label' => 'Logout'
        }
      ]
    }
  end

  delegate :iiif_auth_api_url, :logout_url, :iiif_token_api_url, to: :url_helpers

  def url_helpers
    @context
  end
end
