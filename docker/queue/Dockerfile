FROM php:8.4-fpm

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    curl \
    ca-certificates \
    gnupg2 \
    libpng-dev \
    libxml2-dev \
    zip \
    bash \
    unzip \
    libonig-dev \
    libicu-dev \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libzip-dev \
    supervisor \
    openssh-server \
    apache2-utils \
    autoconf \
    gcc \
    g++ \
    make \
    cron \
    nodejs \
    npm \
    unixodbc-dev \
    && rm -rf /var/lib/apt/lists/*

# Install Microsoft ODBC driver for SQL Server
RUN set -e; \
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/microsoft.gpg; \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft.gpg] https://packages.microsoft.com/debian/12/prod bookworm main" > /etc/apt/sources.list.d/microsoft-prod.list; \
    apt-get update; \
    ACCEPT_EULA=Y apt-get install -y --no-install-recommends msodbcsql18; \
    rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install pdo_mysql mbstring exif pcntl bcmath gd intl zip

# Install Redis extension using PECL
RUN pecl install redis && docker-php-ext-enable redis

# Install sqlsrv
RUN pecl install sqlsrv pdo_sqlsrv \
    && docker-php-ext-enable sqlsrv pdo_sqlsrv \
    && rm -rf /tmp/pear

# Copy custom PHP configuration
COPY docker/queue/php.ini /usr/local/etc/php/conf.d/custom-php.ini

# Install Composer
COPY --from=composer:latest /usr/bin/composer /usr/bin/composer

# Configure SSH
RUN mkdir -p /var/run/sshd
RUN echo 'root:root' | chpasswd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN ssh-keygen -A

# Configure PHP-FPM
RUN sed -i 's/listen = 127.0.0.1:9000/listen = 9000/' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i 's/;listen.owner = www-data/listen.owner = www-data/' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i 's/;listen.group = www-data/listen.group = www-data/' /usr/local/etc/php-fpm.d/www.conf
RUN sed -i 's/;listen.mode = 0660/listen.mode = 0660/' /usr/local/etc/php-fpm.d/www.conf

# Set working directory
WORKDIR /var/www/html

# Copy application files
COPY . /var/www/html

# Copy configurations
COPY docker/queue/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
COPY docker/queue/start.sh /start.sh

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
RUN git config --global --add safe.directory /var/www/html
RUN composer install --no-dev --optimize-autoloader || true

# Generate Laravel application key if .env exists
RUN if [ -f .env ]; then php artisan key:generate --force; fi

# Clear and cache Laravel configuration (if .env exists)
RUN if [ -f .env ]; then php artisan config:cache; fi
RUN if [ -f .env ]; then php artisan route:cache; fi
RUN if [ -f .env ]; then php artisan view:cache; fi

RUN chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
RUN chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

# Create log directories
RUN mkdir -p /var/log/supervisor

# Expose ports
EXPOSE 22

# Start supervisor which will manage all services
CMD ["/bin/sh", "/start.sh"]
