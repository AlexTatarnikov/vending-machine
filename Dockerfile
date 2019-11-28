FROM ruby:2.6.5

WORKDIR /usr/src/app

ENV LANG en_US.UTF-8

ADD Gemfile /usr/src/app/Gemfile
ADD Gemfile.lock /usr/src/app/Gemfile.lock

ADD . /usr/src/app

RUN bundle install --jobs 20 --retry 5