# frozen_string_literal: true

# Responsible for creating a connection to an image metadata service
class StacksMetadataServiceFactory < DriverFactory
  def self.key
    :metadata
  end
  private_class_method :key
end
