ARG RUBY_VERSION=3.2.2-alpine
FROM ruby:$RUBY_VERSION

RUN apk add --update --no-cache  \
  build-base \
  git \
  tzdata

WORKDIR /app

ENV RAILS_ENV="production" \
    BUNDLER_WITHOUT="development test" \
    RAILS_SERVE_STATIC_FILES="true"

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile --gemfile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 bundle exec rails assets:precompile

EXPOSE 3000
CMD ["./bin/rails", "server"]