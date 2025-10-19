#!/bin/sh

echo "Starting unified Laravel container..."
echo "Container updated at: $(date)"

# Set working directory
cd /var/www/html

# Ensure proper permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

# Wait for database to be ready
echo "Waiting for database to be ready..."
until nc -z mysql 3306; do
    echo "Waiting for MySQL to be ready..."
    sleep 2
done
echo "Database is ready!"

# Install/update composer dependencies if enabled and composer.json exists
if [ "${AUTO_INSTALL_COMPOSER:-true}" = "true" ] && [ -f "/var/www/html/composer.json" ]; then
    echo "Installing/updating composer dependencies..."
    composer install --no-dev --optimize-autoloader --no-interaction || {
        echo "ERROR: Composer install failed!"
        exit 1
    }
    echo "Composer dependencies installed successfully!"
fi

# Run Laravel setup and migrations if artisan exists
if [ -f "/var/www/html/artisan" ]; then
    echo "Running Laravel setup..."
    
    # Generate app key if not exists
    if ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
        echo "Generating application key..."
        php artisan key:generate --force || true
    fi
    
    # Clear old cache
    echo "Clearing caches..."
    php artisan config:clear 2>/dev/null || true
    php artisan route:clear 2>/dev/null || true
    php artisan view:clear 2>/dev/null || true
    
    # Run migrations if enabled
    if [ "${AUTO_RUN_MIGRATIONS:-true}" = "true" ]; then
        echo "Running database migrations..."
        php artisan migrate --force || {
            echo "ERROR: Migration failed!"
            exit 1
        }
        echo "Migrations completed successfully!"
    fi
    
    # Cache configurations
    echo "Caching configurations..."
    php artisan config:cache 2>/dev/null || true
    php artisan route:cache 2>/dev/null || true  
    php artisan view:cache 2>/dev/null || true
fi

echo "Authentication is handled by Laravel middleware based on AUTH environment variable"
echo "Current AUTH setting: ${AUTH:-none}"

# Create log directories for supervisor
mkdir -p /var/log/supervisor

# Check if supervisord config exists
if [ ! -f "/etc/supervisor/conf.d/supervisord.conf" ]; then
    echo "ERROR: supervisord.conf not found!"
    exit 1
fi

bun install --frozen-lockfile && bun run build

# adjust folder permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true

# Start supervisor which will manage nginx, php-fpm, ssh, workers, and cron
echo "Starting supervisor with all services..."
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
