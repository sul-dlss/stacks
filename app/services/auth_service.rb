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
      'label' => 'Stanford users: log in to access all available features.',
      'header' => 'Stanford-affiliated? Log in to view',
      'description' => 'Stanford users can click Log in below to access all fea'\
        'tures.',
      'confirmLabel' => 'Log in',
      'failureHeader' => 'Unable to authenticate',
      'failureDescription' => 'The authentication service cannot be reached.',
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
