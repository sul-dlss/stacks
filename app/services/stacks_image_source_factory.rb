# Responsible for creating a connection to an image image service
class StacksImageSourceFactory
  def self.create(id:, file_name:, transformation:)
    image_source_class.new(id: id, file_name: file_name, transformation: transformation, url: image_source_url)
  end

  def self.image_source_class
    Settings.stacks[driver].image.implementation.constantize
  end

  def self.image_source_url
    Settings.stacks[driver].image.attributes.url
  end

  private_class_method :image_source_class

  def self.driver
    Settings.stacks.driver
  end
  private_class_method :driver
end
