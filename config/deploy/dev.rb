server 'sul-stacks-dev.stanford.edu', user: 'stacks', roles: %w{web app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'development'

set :bundle_without, %w{deployment test}.join(' ')
