# frozen_string_literal: true

# A custom exceptions class to provide specific Stacks::Exceptions
module Stacks
  # An UnexpectedMetadataResponse to raise when HTTP returns bad JSON
  class UnexpectedMetadataResponseError < StandardError
    def initialize(url = nil, error = nil, json = nil)
      msg = "There was a problem fetching #{url}. Server returned invalid JSON with message: #{error}. DATA: #{json}"
      Rails.logger.error msg
      super(msg)
    end
  end
end
