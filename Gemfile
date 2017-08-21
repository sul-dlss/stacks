source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 5.1.0'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use Puma as the app server
gem 'puma', '~> 3.7'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 2.7.2'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.2'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.5'

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', require: false

  # Call 'binding.pry' anywhere in the code to stop execution and get a pry console
  gem 'pry-byebug', require: false

  # RSpec for testing
  gem 'rspec-rails', '~> 3.0'

  gem 'rails-controller-testing'

  # Capybara for feature/integration tests
  gem 'capybara'

  # factory_girl_rails for creating fixtures in tests
  gem 'factory_girl_rails'

  # Poltergeist is a capybara driver to run integration tests using PhantomJS
  gem 'poltergeist'

  # Database cleaner allows us to clean the entire database after certain tests
  gem 'database_cleaner'

  # Rubocop is a static code analyzer to enforce style.
  gem 'rubocop', '= 0.46.0', require: false

  # scss-lint will test the scss files to enfoce styles
  gem 'scss-lint', require: false

  # Coveralls for code coverage metrics
  gem 'coveralls', require: false
end

group :test do
  gem 'codeclimate-test-reporter', require: false
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

gem 'bootstrap-sass'
gem 'sul_styles'
gem 'djatoka'
gem 'riiif'
gem 'config'
gem 'faraday'
gem 'http'
gem 'cancancan'
gem 'dor-rights-auth', require: 'dor/rights_auth'
gem 'dalli'
gem 'retries'
