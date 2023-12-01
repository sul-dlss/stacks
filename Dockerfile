ARG RUBY_VERSION=3.2.2-alpine
FROM ruby:$RUBY_VERSION

RUN apk add --update --no-cache  \
  build-base \
  git \
  tzdata

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install

COPY . .

EXPOSE 3000
CMD ["./bin/rails", "server", "--binding=0.0.0.0"]
