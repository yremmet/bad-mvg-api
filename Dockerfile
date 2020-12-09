FROM ruby:2.7.1

ENV PORT=8080
ENV ACCEPT_WEB_CONCURRENCY=5

WORKDIR /usr/src/app
RUN     gem install bundler:2.0.1 
COPY    Gemfile Gemfile.lock unicorn.rb config.ru ./
RUN     bundle install
COPY    bad-mvg-api.rb ./

EXPOSE 8080
CMD     bundle exec unicorn --port $PORT --config-file unicorn.rb
