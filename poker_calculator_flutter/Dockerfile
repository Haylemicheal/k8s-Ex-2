# Build stage
FROM ghcr.io/cirruslabs/flutter:stable AS build

WORKDIR /app

# Accept build argument for API URL
ARG API_URL=http://localhost:8080

# Copy pubspec files
COPY pubspec.yaml pubspec.lock* ./

# Get dependencies
# Note: Flutter may show a warning about running as root, but this is non-fatal in Docker
RUN flutter pub get

# Copy source code
COPY . .

# Build for web with API URL
# Note: --web-renderer flag was removed in newer Flutter versions
# The root user warning is non-fatal and can be safely ignored in Docker builds
RUN flutter build web --release --dart-define=API_URL=$API_URL

# Production stage
FROM nginx:alpine

# Copy built web files
COPY --from=build /app/build/web /usr/share/nginx/html

# Copy nginx configuration
RUN echo 'server { \
    listen 80; \
    server_name _; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
}' > /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
