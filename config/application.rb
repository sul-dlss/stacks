# frozen_string_literal: true

require_relative 'boot'

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
require "action_view/railtie"
# require "action_cable/engine"
require "sprockets/railtie"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DigitalStacks
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.0

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Swap out the default RemoteIp configuration with one configured for our
    # load-balancers. The generic configuration will ignore all internal IPs
    # (e.g. 172.xxx or 10.xx), which are used on campus and we want to know about.
    config.middleware.swap ActionDispatch::RemoteIp,
                           ActionDispatch::RemoteIp,
                           true,
                           [
                             "127.0.0.1", # localhost IPv4
                             "::1", # localhost IPv6
                             "172.20.21.208/28", # foa_lb_mgmt_dev_nets
                             "172.20.21.192/28" # foa_lb_mgmt_prod_nets
                           ].map { |proxy| IPAddr.new(proxy) }
  end
end
