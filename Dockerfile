FROM ruby:2.7.5-slim-buster

# RUN apt-get update \
#  && apt-get install -y \
#  && vim \
#  && apt-get clean \
#  && rm -rf /var/lib/apt/lists/*

RUN gem install bundler -v 2.1.4 --without test

WORKDIR /app

COPY Gemfile /app/Gemfile
COPY Gemfile.lock /app/Gemfile.lock
RUN bundle install --without development test

COPY solar_edge.rb /app

RUN useradd -ms /bin/bash solar
RUN chown -R solar:solar /app
USER solar

CMD [ "bundle", "exec", "ruby", "solar_edge.rb" ]
