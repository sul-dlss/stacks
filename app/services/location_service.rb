# frozen_string_literal: true

# Produces iiif service for location based access
class LocationService
  # helper method to create a new location service
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
      'profile' => 'http://iiif.io/api/auth/1/external',
      '@id' => 'https://sul-stacks-uat.stanford.edu/auth/iiif',
      'label' => 'External Authentication Required',
      'failureHeader' => 'Restricted Material',
      'failureDescription' => 'Restricted content cannot be accessed from your location',
      'service' => [
        {
          '@id' => iiif_token_api_url,
          'profile' => 'http://iiif.io/api/auth/1/token'
        }
      ]
    }
  end

  delegate :iiif_token_api_url, to: :url_helpers

  def url_helpers
    @context
  end
end
