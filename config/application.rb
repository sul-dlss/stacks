require_relative 'boot'

require "rails"

# Not loading active_record, action_cable, active_job, action_mailer
# added active_model/railtie
# See https://github.com/rails/rails/blob/5.1.3/railties/lib/rails/all.rb
%w(
  action_controller/railtie
  action_view/railtie
  active_model/railtie
  rails/test_unit/railtie
  sprockets/railtie
).each do |railtie|
  begin
    require railtie
  rescue LoadError
  end
end

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DigitalStacks
  class Application < Rails::Application
    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
