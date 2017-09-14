# Responsible for creating a connection to an image image service
class StacksInfoServiceFactory
  def self.create(image)
    info_service_class.new(image)
  end

  def self.info_service_class
    Settings.stacks[driver].info.implementation.constantize
  end
  private_class_method :info_service_class

  def self.driver
    Settings.stacks.driver
  end
  private_class_method :driver
end
