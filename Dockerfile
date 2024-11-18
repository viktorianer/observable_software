# syntax=docker/dockerfile:1
# check=error=false

# This Dockerfile is designed for production, not development. Use with Kamal or build'n'run by hand:
# docker build -t mini_cross_stitching .
# docker run -d -p 80:80 -e RAILS_MASTER_KEY=<value from config/master.key> --name mini_cross_stitching mini_cross_stitching

# For a containerized dev environment, see Dev Containers: https://guides.rubyonrails.org/getting_started_with_devcontainer.html

# Make sure RUBY_VERSION matches the Ruby version in .ruby-version
ARG RUBY_VERSION=3.3.4
FROM docker.io/library/ruby:$RUBY_VERSION-slim AS base

# Rails app lives here
WORKDIR /rails

RUN apt-get update && apt-get install -y \
    ca-certificates \
    curl \
    fonts-liberation \
    libappindicator3-1 \
    libasound2 \
    libatk-bridge2.0-0 \
    libatk1.0-0 \
    libgdk-pixbuf2.0-0 \
    libnspr4 \
    libnss3 \
    libx11-xcb1 \
    libxcomposite1 \
    libxdamage1 \
    libxrandr2 \
    xdg-utils \
    wget \
    firefox-esr \
    gnupg \
    wget \
    libvulkan1 \
    && rm -rf /var/lib/apt/lists/*

# Install base packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y curl libjemalloc2 libvips sqlite3 imagemagick && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Throw-away build stage to reduce size of final image
FROM base AS build

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    RAILS_MASTER_KEY=9c895fb07eb7538267fd094b854fa131 \
    SECRET_KEY_BASE=8fc08abe7101032ef1b640b1df8107914f31e481f6e02671534efdb82c853b425ee370563416f86fdf90db39924e3e3704223aa18ddcdcb707820e1fc53473ce \
    BUNDLE_WITHOUT="development"

# Print environment variables
RUN echo "Environment variables are set:  "
RUN printenv

RUN echo "Rails master key 1: ${#RAILS_MASTER_KEY}"
RUN echo "Secret key base 1: ${#SECRET_KEY_BASE}"

# Install packages needed to build gems
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y build-essential git pkg-config && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install application gems
COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git && \
    bundle exec bootsnap precompile --gemfile

# Copy application code
COPY . .

# Precompile bootsnap code for faster boot times
RUN bundle exec bootsnap precompile app/ lib/

# Precompiling assets for production without requiring secret RAILS_MASTER_KEY
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile


RUN echo "Rails master key: ${#RAILS_MASTER_KEY}"
RUN echo "Secret key base: ${#SECRET_KEY_BASE}"


# Add this near your entrypoint configuration
COPY <<-"EOF" /rails/bin/healthcheck
#!/bin/bash
set -e

if [ -z "$RAILS_MASTER_KEY" ]; then
  echo "RAILS_MASTER_KEY is not set"
  exit 1
fi

if [ -z "$SECRET_KEY_BASE" ]; then
  echo "SECRET_KEY_BASE is not set"
  exit 1
fi

exit 0
EOF

RUN chmod +x /rails/bin/healthcheck
HEALTHCHECK --interval=5s --timeout=3s --start-period=10s --retries=3 CMD [ "/rails/bin/healthcheck" ]


# Final stage for app image
FROM base

# Copy built artifacts: gems, application
COPY --from=build "${BUNDLE_PATH}" "${BUNDLE_PATH}"
COPY --from=build /rails /rails

# Run and own only the runtime files as a non-root user for security
RUN groupadd --system --gid 1000 rails && \
    useradd rails --uid 1000 --gid 1000 --create-home --shell /bin/bash && \
    chown -R rails:rails db log storage tmp
USER 1000:1000

# Entrypoint prepares the database.
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

# Start server via Thruster by default, this can be overwritten at runtime
EXPOSE 80
CMD ["./bin/thrust", "./bin/rails", "server"]
