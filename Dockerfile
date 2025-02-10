FROM ruby:2.7.7

RUN apt update && apt install build-essential
RUN gem install bundler -v 2.4.22

COPY Gemfile /Gemfile
COPY Gemfile.lock /Gemfile.lock

RUN bundle
