FROM ruby:2.4.1-alpine

RUN mkdir app
WORKDIR /app
ADD Gemfile /app/Gemfile
ADD Gemfile.lock /app/Gemfile.lock
RUN apk --update add --no-cache --virtual .ruby-builddeps \
      make gcc g++ linux-headers
RUN gem update bundler && bundle install

EXPOSE 3500
CMD ["ash"]
