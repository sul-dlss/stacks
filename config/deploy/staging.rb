server 'sul-stacks-test.stanford.edu', user: 'stacks', roles: %w{web db app}

Capistrano::OneTimeKey.generate_one_time_key!
set :rails_env, "production"
set :branch, ENV["BRANCH"] || "master"

