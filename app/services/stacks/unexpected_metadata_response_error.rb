# frozen_string_literal: true

# A custom exceptions class to provide specific Stacks::Exceptions
module Stacks
  # An UnexpectedMetadataResponse to raise when HTTP returns bad JSON
  class UnexpectedMetadataResponseError < StandardError; end
end
