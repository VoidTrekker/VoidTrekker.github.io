# ---------- Stage 1: Build the Jekyll site ----------
FROM ruby:3.2-bookworm AS builder

# System deps for Jekyll + assets
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential git nodejs imagemagick ca-certificates \
    python3 python3-pip pandoc \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /site

# Install gems first
COPY Gemfile ./
RUN bundle config set without 'development test' && \
    (bundle lock --add-platform aarch64-linux || true) && \
    (bundle lock --add-platform x86_64-linux || true) && \
    bundle install --jobs 4

# Copy the rest of the site and build
COPY . .
RUN bundle exec jekyll build --trace

# ---------- Stage 2: Serve the static site ----------
FROM nginx:stable-alpine
COPY --from=builder /site/_site/ /usr/share/nginx/html/
EXPOSE 80
HEALTHCHECK CMD wget -qO- http://localhost/ >/dev/null 2>&1 || exit 1