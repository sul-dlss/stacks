# frozen_string_literal: true

# Creates a okcompter check to see that the Iiif server is up
class CheckIiif < EndpointCheck
  def self.uri_to_check
    Settings.stacks['remote_iiif'].image.attributes.base_uri
  end
end
