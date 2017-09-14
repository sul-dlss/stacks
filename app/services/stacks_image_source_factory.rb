# Responsible for creating a connection to an image image service
class StacksImageSourceFactory
  def self.create(id:, file_name:, transformation:)
    image_source_class.new(id: id, file_name: file_name, transformation: transformation, **attributes)
  end

  def self.image_source_class
    config.implementation.constantize
  end
  private_class_method :image_source_class

  def self.attributes
    config.attributes
  end
  private_class_method :attributes

  def self.config
    Settings.stacks[driver].image
  end
  private_class_method :config

  def self.driver
    Settings.stacks.driver
  end
  private_class_method :driver
end
