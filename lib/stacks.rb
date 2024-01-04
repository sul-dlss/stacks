# frozen_string_literal: true

# A custom exceptions class to provide specific Stacks::Exceptions
module Stacks
  # An UnexpectedMetadataResponse to raise when HTTP returns bad JSON
  class UnexpectedMetadataResponseError < StandardError; end

  # RetrieveMetadataError is raised when there is an error retrieving metadata
  # from the image server.
  class RetrieveMetadataError < StandardError; end

  # ImageServerUnavailable is raised when the image server returns
  # 503 Service Unavailable
  class ImageServerUnavailable < RetrieveMetadataError; end
end
