FROM php:8.4-fpm-alpine

# Install system dependencies
RUN apk add --no-cache \
    git \
    curl \
    libpng-dev \
    libxml2-dev \
    zip \
    bash \
    unzip \
    oniguruma-dev \
    icu-dev \
    freetype-dev \
    libjpeg-turbo-dev \
    libzip-dev \
    supervisor \
    openssh-server \
    openssh-client \
    nginx \
    apache2-utils \
    autoconf \
    gcc \
    g++ \
    make \
    dcron \
    nodejs \
    npm

# Clear cache
RUN rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip

# Install Redis extension using PECL
RUN pecl install redis && docker-php-ext-enable redis

# Copy custom PHP configuration
COPY docker/app/php.ini /usr/local/etc/php/conf.d/custom-php.ini

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configure PHP-FPM
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i 's/;listen.owner = www-data/listen.owner = www-data/' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i 's/;listen.group = www-data/listen.group = www-data/' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i 's/;listen.mode = 0660/listen.mode = 0660/' /usr/local/etc/php-fpm.d/www.conf

# Set working directory
WORKDIR /var/www/html

# Configure nginx user and directories
RUN adduser -D -s /bin/sh nginx nginx || true
RUN mkdir -p /var/log/nginx /var/lib/nginx/tmp /var/cache/nginx
RUN chown -R nginx:nginx /var/log/nginx /var/lib/nginx /var/cache/nginx
RUN chmod -R 755 /var/log/nginx /var/lib/nginx /var/cache/nginx

# Copy application files
COPY . /var/www/html

# Copy configurations
COPY docker/app/nginx.conf /etc/nginx/nginx.conf
COPY docker/app/default.conf /etc/nginx/conf.d/default.conf
COPY docker/app/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/app/start.sh /start.sh

# Create .htpasswd file
RUN touch /etc/nginx/.htpasswd

# Make start script executable
RUN chmod +x /start.sh

# Create required directories and set permissions before composer install
RUN mkdir -p /var/www/html/bootstrap/cache /var/www/html/storage/app /var/www/html/storage/framework/cache /var/www/html/storage/framework/sessions /var/www/html/storage/framework/views /var/www/html/storage/logs
RUN chown -R www-data:www-data /var/www/html
RUN chmod -R 755 /var/www/html/storage /var/www/html/bootstrap/cache

RUN curl -fsSL https://bun.sh/install | bash && \
    mv /root/.bun/bin/bun /usr/local/bin/bun
# RUN bun install --frozen-lockfile
# RUN bun install
# RUN bun run build
RUN cp .env.example .env || true
# Install PHP dependencies
RUN composer install --no-dev --optimize-autoloader || true
# RUN composer install

# Generate Laravel application key if .env exists
RUN if [ -f .env ]; then php artisan key:generate --force; fi

# Clear and cache Laravel configuration (if .env exists)
RUN if [ -f .env ]; then php artisan config:cache; fi
RUN if [ -f .env ]; then php artisan route:cache; fi
RUN if [ -f .env ]; then php artisan view:cache; fi

RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

# Create log directories
RUN mkdir -p /var/log/supervisor /var/log/nginx

# Expose ports
EXPOSE 80 443

# Start supervisor which will manage all services
CMD ["/bin/sh", "/start.sh"]
