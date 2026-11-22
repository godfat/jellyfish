FROM ruby:4.0-alpine

RUN apk add --no-cache git

COPY . /src
WORKDIR /src

RUN bundle install
RUN rake test || true
