# Responsible for creating a connection to an image image service
class StacksInfoServiceFactory
  def self.create(image)
    info_service_class.new(image)
  end

  def self.info_service_class
    config.implementation.constantize
  end
  private_class_method :info_service_class

  def self.config
    Settings.stacks[driver].info
  end
  private_class_method :config

  def self.driver
    Settings.stacks.driver
  end
  private_class_method :driver
end
