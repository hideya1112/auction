# syntax=docker/dockerfile:1

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.2.8
FROM docker.io/library/ruby:$RUBY_VERSION-slim

# Rails app lives here
WORKDIR /rails

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    curl \
    git \
    libjemalloc2 \
    libpq-dev \
    libvips \
    postgresql-client \
    vim \
    libyaml-dev \
    libffi-dev \
    zlib1g-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Set development environment
ENV BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT=""

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN gem install bundler && \
    bundle install

# Copy application code
COPY . .

# Create a script to be used as an entrypoint
RUN echo '#!/bin/bash\nset -e\n\n# Remove a potentially pre-existing server.pid for Rails.\nrm -f tmp/pids/server.pid\n\n# Then exec the container'\''s main process (what'\''s set as CMD in the Dockerfile).\nexec "$@"' > /usr/local/bin/docker-entrypoint
RUN chmod +x /usr/local/bin/docker-entrypoint
ENTRYPOINT ["docker-entrypoint"]

# Expose port 3000 to the Docker host, so we can access it
# from the outside.
EXPOSE 3000

# The default command that gets ran will be to start the Rails server.
CMD ["sh", "-c", "bundle exec rails db:create db:migrate && bundle exec rails server -b 0.0.0.0"]