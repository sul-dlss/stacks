# Responsible for creating a connection to an image image service
class StacksImageSourceFactory < DriverFactory
  def self.key
    :image
  end
  private_class_method :key
end
