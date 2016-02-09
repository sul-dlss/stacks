source 'https://rubygems.org'


# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '4.2.5.1'
# Use sqlite3 as the database for Active Record
gem 'sqlite3'
# Use SCSS for stylesheets
gem 'sass-rails', '~> 5.0'
# Use Uglifier as compressor for JavaScript assets
gem 'uglifier', '>= 1.3.0'
# Use CoffeeScript for .coffee assets and views
gem 'coffee-rails', '~> 4.1.0'
# See https://github.com/rails/execjs#readme for more supported runtimes
gem 'therubyracer', platforms: :ruby

# Use jquery as the JavaScript library
gem 'jquery-rails'
# Turbolinks makes following links in your web application faster. Read more: https://github.com/rails/turbolinks
gem 'turbolinks'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.0'
# bundle exec rake doc:rails generates the API under doc/api.
gem 'sdoc', '~> 0.4.0', group: :doc

# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Unicorn as the app server
# gem 'unicorn'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

# Access an IRB console on exception pages or by using <%= console %> in views
gem 'web-console', '~> 2.0', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug'

  # RSpec for testing
  gem 'rspec-rails', '~> 3.0'

  # Capybara for feature/integration tests
  gem 'capybara'

  # factory_girl_rails for creating fixtures in tests
  gem 'factory_girl_rails'

  # Poltergeist is a capybara driver to run integration tests using PhantomJS
  gem 'poltergeist'

  # Database cleaner allows us to clean the entire database after certain tests
  gem 'database_cleaner'

  # Rubocop is a static code analyzer to enforce style.
  gem 'rubocop', require: false

  # scss-lint will test the scss files to enfoce styles
  gem 'scss-lint', require: false

  # Coveralls for code coverage metrics
  gem 'coveralls', require: false
end

group :test do
  gem 'webmock'
  gem 'vcr'
end

# Use Capistrano for deployment
group :deployment do
  gem 'capistrano', '~> 3.0'
  gem 'capistrano-rvm'
  gem 'capistrano-bundler'
  gem 'capistrano-rails'
  gem 'capistrano-passenger'
  gem 'dlss-capistrano'
end

# Use Squash for exception reporting
gem 'squash_ruby', require: 'squash/ruby'

# Pinned to 1.3.3 until https://github.com/SquareSquash/rails/pull/15
gem 'squash_rails', '1.3.3', require: 'squash/rails'

gem 'is_it_working'
gem 'bootstrap-sass'
gem 'sul_styles'
gem 'djatoka'
gem 'riiif'
gem 'config'
gem 'hurley'
gem 'cancancan'
gem 'dor-rights-auth', require: 'dor/rights_auth'
gem 'dalli'
