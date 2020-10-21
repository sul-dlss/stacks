require 'okcomputer'

# /status for 'upness' (Rails app is responding), e.g. for load balancer
# /status/all to show all dependencies
# /status/<name-of-check> for a specific check (e.g. for nagios warning)
OkComputer.mount_at = 'status'
OkComputer.check_in_parallel = true
OkComputer::Registry.deregister "database" # don't check (unused) ActiveRecord database conn

# REQUIRED checks, required to pass for /status/all
#  individual checks also avail at /status/<name-of-check>
OkComputer::Registry.register 'ruby_version', OkComputer::RubyVersionCheck.new
# TODO: add app version check when okcomputer works with cap 3 (see http://github.com/sportngin/okcomputer#112)

OkComputer::Registry.register 'rails_cache', OkComputer::GenericCacheCheck.new

OkComputer::Registry.register 'stacks_mounted_dir',
  OkComputer::DirectoryCheck.new(Settings.stacks.storage_root)

OkComputer::Registry.register 'purl_url', OkComputer::HttpCheck.new(Settings.purl.url + "status/default.json")

OkComputer::Registry.register 'redis', OkComputer::RedisCheck.new(Settings.cdl.redis.to_h) if Settings.cdl.redis
OkComputer.make_optional %w(redis)
# ------------------------------------------------------------------------------

# NON-CRUCIAL (Optional) checks, avail at /status/<name-of-check>
#   - at individual endpoint, HTTP response code reflects the actual result
#   - in /status/all, these checks will display their result text, but will not affect HTTP response code

# For image content in image viewer
OkComputer::Registry.register 'imageserver_url', OkComputer::HttpCheck.new(Settings.imageserver.base_uri)
OkComputer.make_optional %w(imageserver_url)
