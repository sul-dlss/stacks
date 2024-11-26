require_relative "boot"

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
# require "active_record/railtie"
# require "active_storage/engine"
require "action_controller/railtie"
# require "action_mailer/railtie"
# require "action_mailbox/engine"
# require "action_text/engine"
require "action_view/railtie"
# require "action_cable/engine"
require "rails/test_unit/railtie"

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module DigitalStacks
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.1

    # Please, add to the `ignore` list any other `lib` subdirectories that do
    # not contain `.rb` files, or that should not be reloaded or eager loaded.
    # Common ones are `templates`, `generators`, or `middleware`, for example.
    config.autoload_lib(ignore: %w(assets tasks))

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")

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

    # IIIF Auth v2 makes a request in one window to login and then opens a iframe to get a token.
    # In order for this second request to know who the user is, the session token must created with SameSite=None
    config.action_dispatch.cookies_same_site_protection = :none

    # Use ActiveJob async adapter for all environments – our only jobs are
    # for tracking metrics and they execute very quickly, so there's no need
    # for a dedicated redis instance or similar
    config.active_job.queue_adapter = :async
  end
end
