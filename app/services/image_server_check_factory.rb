# A factory that produces the correct checks for the configured image server
class ImageServerCheckFactory < DriverFactory
  def self.ok_check
    implementation.ok_check
  end

  def self.key
    :check
  end
  private_class_method :key
end
