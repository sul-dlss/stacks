# @abstract Parent class for factories that use the settings.yml
class DriverFactory
  # Instantiate the implementation class with all passed arguments and
  # configured attributes
  def self.create(**kwargs)
    implementation.new(**kwargs.merge(attributes))
  end

  def self.attributes
    config.attributes
  end
  private_class_method :attributes

  def self.implementation
    impl_string = config.implementation
    key_error!('implementation') unless impl_string
    impl_string.constantize
  end
  private_class_method :implementation

  def self.driver
    Settings.stacks.driver
  end
  private_class_method :driver

  def self.config
    driver_config[key] || key_error!
  end
  private_class_method :config

  def self.driver_config
    Settings.stacks[driver]
  end
  private_class_method :driver_config

  def self.key_error!(variable = '')
    variable = [driver, key, variable].reject(&:blank?).join('.')
    raise KeyError, "Unable to find '#{variable}' in the settings"
  end
end
