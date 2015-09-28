server 'sul-stacks-prod-b.stanford.edu', user: 'stacks', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, "production"
