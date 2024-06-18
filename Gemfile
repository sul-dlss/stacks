source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 7.1.1'
# asset pipeline for Rails
gem 'propshaft'

# Use Puma as the app server
gem 'puma', '~> 6.0'

# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'

# Reduces boot times through caching; required in config/boot.rb
gem 'bootsnap', '>= 1.4.2', require: false

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 4.1.0'
end

group :development, :test do
  # See https://guides.rubyonrails.org/debugging_rails_applications.html#debugging-with-the-debug-gem
  gem "debug", platforms: %i[ mri mingw x64_mingw ]

  # RSpec for testing
  gem 'rspec-rails', '~> 6.0'

  gem 'rails-controller-testing'

  # Capybara for feature/integration tests
  gem 'capybara'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'webdrivers'

  # Rubocop is a static code analyzer to enforce style.
  gem 'rubocop', '~> 1.57', require: false
  gem 'rubocop-capybara', require: false
  gem 'rubocop-performance', require: false
  gem 'rubocop-rails', require: false
  gem 'rubocop-rspec', require: false
  gem 'rubocop-rspec_rails', require: false

  gem 'simplecov'
  gem 'webmock', '~> 3.0'
end

# Use Capistrano for deployment
group :deployment do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'capistrano-shared_configs'
  gem 'dlss-capistrano'
end

# Use Honeybadger for exception reporting
gem 'honeybadger'

# Use okcomputer to monitor the application
gem 'okcomputer'
gem 'iiif-image-api', '~> 0.2'
gem 'config'
gem 'faraday'
gem 'http'
gem 'cancancan'
gem 'dalli'
gem 'retries'
gem 'zipline', '~> 1.2'
gem 'jwt'
gem 'redis'
gem 'ocfl'

# connection_pool required for thread-safe operations in dalli >= 3.0
# see https://github.com/petergoldstein/dalli/blob/v3.0.0/3.0-Upgrade.md
gem 'connection_pool'

group :production do
  gem 'newrelic_rpm'
end
