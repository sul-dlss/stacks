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

# ------------------------------------------------------------------------------

# NON-CRUCIAL (Optional) checks, avail at /status/<name-of-check>
#   - at individual endpoint, HTTP response code reflects the actual result
#   - in /status/all, these checks will display their result text, but will not affect HTTP response code

# For image content in image viewer
djatoka_url_to_check = Settings.stacks.djatoka_url + '?rft_id=/&svc_id=info:lanl-repo/svc/ping&url_ver=Z39.88-2004'
OkComputer::Registry.register 'imageserver_url', OkComputer::HttpCheck.new(djatoka_url_to_check)
OkComputer.make_optional %w(imageserver_url)
