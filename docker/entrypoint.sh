#!/bin/sh

echo "=== Laravel Docker Container Entrypoint ==="
echo "Container started at: $(date)"
echo "Container update trigger: ${CONTAINER_UPDATE_TRIGGER:-manual}"

# Check if this is a container update (rebuild/restart)
if [ "${FORCE_UPDATE:-false}" = "true" ] || [ ! -f "/tmp/.container_initialized" ]; then
    echo "=== CONTAINER UPDATE DETECTED ==="
    echo "Running update procedures..."
    
    # Set working directory
    cd /var/www/html
    
    # Ensure proper permissions first
    echo "Setting permissions..."
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
    
    # Force composer install
    if [ -f "/var/www/html/composer.json" ]; then
        echo "=== RUNNING COMPOSER INSTALL ==="
        composer install --no-dev --optimize-autoloader --no-interaction || {
            echo "ERROR: Composer install failed!"
            exit 1
        }
        echo "✓ Composer dependencies updated"
    fi
    
    # Force Laravel setup
    if [ -f "/var/www/html/artisan" ]; then
        echo "=== RUNNING LARAVEL SETUP ==="
        
        # Clear all caches first
        echo "Clearing caches..."
        php artisan config:clear || true
        php artisan route:clear || true
        php artisan view:clear || true
        php artisan cache:clear || true
        
        # Generate key if needed
        if ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
            echo "Generating application key..."
            php artisan key:generate --force || true
        fi
        
        # Run migrations
        echo "=== RUNNING MIGRATIONS ==="
        php artisan migrate --force || {
            echo "ERROR: Migration failed!"
            exit 1
        }
        echo "✓ Migrations completed"
        
        # Recache everything
        echo "Rebuilding caches..."
        php artisan config:cache || true
        php artisan route:cache || true
        php artisan view:cache || true
    fi
    
    # Mark container as initialized
    touch /tmp/.container_initialized
    echo "=== UPDATE PROCEDURES COMPLETED ==="
else
    echo "Container already initialized, skipping update procedures"
fi

echo "=== STARTING MAIN APPLICATION ==="
# Execute the main start script
exec /start.sh