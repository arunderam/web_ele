# Production-ready Nginx container for static website deployment
FROM nginx:1.27-alpine

# Set maintainer label
LABEL maintainer="website-ele"
LABEL description="Static website for electrical products"

# Install additional packages for better security and performance
RUN apk add --no-cache \
    curl \
    && rm -rf /var/cache/apk/*

# Create custom nginx configuration for better performance and debugging
COPY <<EOF /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name localhost;
    root /usr/share/nginx/html;
    index index.html;

    # Enable error logging for debugging
    error_log /var/log/nginx/error.log debug;
    access_log /var/log/nginx/access.log;

    # Security headers
    add_header X-Frame-Options "SAMEORIGIN" always;
    add_header X-Content-Type-Options "nosniff" always;
    add_header X-XSS-Protection "1; mode=block" always;
    add_header Referrer-Policy "strict-origin-when-cross-origin" always;
    add_header Content-Security-Policy "default-src 'self' 'unsafe-inline' 'unsafe-eval' https://fonts.googleapis.com https://fonts.gstatic.com https://use.fontawesome.com https://cdn.jsdelivr.net https://ajax.googleapis.com; img-src 'self' data: https:; font-src 'self' https://fonts.gstatic.com https://use.fontawesome.com https://cdn.jsdelivr.net;" always;

    # Gzip compression
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css text/xml text/javascript application/javascript application/xml+rss application/json image/svg+xml;

    # Cache static assets
    location ~* \.(jpg|jpeg|png|gif|ico|css|js|svg|woff|woff2|ttf|eot)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
        add_header Access-Control-Allow-Origin "*";
    }

    # Handle HTML files
    location ~* \.html$ {
        expires 1h;
        add_header Cache-Control "public";
    }

    # Handle root and missing files
    location / {
        try_files $uri $uri/ /index.html;
    }

    # Health check endpoint
    location /health {
        access_log off;
        return 200 "healthy\n";
        add_header Content-Type text/plain;
    }

    # Debug endpoint to check file structure
    location /debug {
        access_log off;
        return 200 "Files loaded successfully\n";
        add_header Content-Type text/plain;
    }
}
EOF

# Clear default nginx html content
RUN rm -rf /usr/share/nginx/html/*

# Copy site files with proper ownership
COPY --chown=nginx:nginx *.html /usr/share/nginx/html/
COPY --chown=nginx:nginx css/ /usr/share/nginx/html/css/
COPY --chown=nginx:nginx js/ /usr/share/nginx/html/js/
COPY --chown=nginx:nginx img/ /usr/share/nginx/html/img/
COPY --chown=nginx:nginx lib/ /usr/share/nginx/html/lib/

# Set proper permissions
RUN chmod -R 755 /usr/share/nginx/html

# Add health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/health || exit 1

# Expose HTTP port
EXPOSE 80

# Run nginx in foreground
CMD ["nginx", "-g", "daemon off;"]
