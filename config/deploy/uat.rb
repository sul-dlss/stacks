server 'sul-stacks-uat.stanford.edu', user: 'stacks', roles: %w{web app db}
server 'sul-stacks-uat-b.stanford.edu', user: 'stacks', roles: %w{web app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, 'production'

set :bundle_without, %w{deployment development test}.join(' ')
