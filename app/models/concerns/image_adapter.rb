# Module for storing a configurable Image Server Resolver
module ImageAdapter
  # Resolver class allows catching the endpoint for the Image Server
  class Resolver
    class_attribute :endpoint
  end
end
