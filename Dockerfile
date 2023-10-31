FROM ruby:2.7.7

RUN apt update && apt install build-essential
RUN gem install bundler

COPY Gemfile /Gemfile
COPY Gemfile.lock /Gemfile.lock

RUN bundle
