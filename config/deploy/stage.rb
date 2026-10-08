# Note, LB with http2 at: https://stacks-stage.stanford.edu/
server 'sul-stacks-stage.stanford.edu', user: 'stacks', roles: %w{web app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'production'

set :bundle_without, %w{deployment test}.join(' ')
