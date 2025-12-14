#!/bin/sh

echo "=== Laravel Docker Container Entrypoint ==="
echo "Container started at: $(date)"

# Set working directory
cd /var/www/html

# Create .env file if it doesn't exist (do this first)
if [ ! -f ".env" ] && [ -f ".env.example" ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
fi

# Check if this is a container update (rebuild/restart)
if [ "${FORCE_UPDATE:-false}" = "true" ] || [ ! -f "/tmp/.container_initialized" ]; then
    echo "=== INITIALIZATION DETECTED ==="
    echo "Running one-time setup procedures..."
    
    # Install composer dependencies
    if [ -f "/var/www/html/composer.json" ]; then
        echo "=== Installing Composer dependencies ==="
        composer install --no-dev --optimize-autoloader --no-interaction || {
            echo "ERROR: Composer install failed!"
            exit 1
        }
        echo "✓ Composer dependencies installed"
    fi
    
    # Laravel setup
    if [ -f "/var/www/html/artisan" ]; then
        echo "=== Running Laravel setup ==="
        
        # Generate app key if not exists
        if ! grep -q "APP_KEY=base64:" .env 2>/dev/null; then
            echo "Generating application key..."
            php artisan key:generate --force || true
        fi
        
        # Clear old caches
        echo "Clearing caches..."
        php artisan config:clear 2>/dev/null || true
        php artisan route:clear 2>/dev/null || true
        php artisan view:clear 2>/dev/null || true
        php artisan cache:clear 2>/dev/null || true
        
        # Run migrations
        echo "=== Running database migrations ==="
        php artisan migrate --force || {
            echo "ERROR: Migration failed!"
            exit 1
        }
        echo "✓ Migrations completed"
        
        # Cache configurations for performance
        echo "Caching configurations..."
        php artisan config:cache 2>/dev/null || true
        php artisan route:cache 2>/dev/null || true
        php artisan view:cache 2>/dev/null || true
    fi
    
    # Build frontend assets
    if [ -f "/var/www/html/package.json" ]; then
        echo "=== Building frontend assets ==="
        bun install --frozen-lockfile && bun run build || {
            echo "WARNING: Frontend build failed, continuing..."
        }
        echo "✓ Frontend assets built"
    fi
    
    # Set proper permissions (do this last)
    echo "Setting final permissions..."
    chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
    chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache 2>/dev/null || true
    
    # Mark container as initialized
    touch /tmp/.container_initialized
    echo "=== INITIALIZATION COMPLETED ==="
else
    echo "Container already initialized, skipping setup procedures"
fi

echo "=== STARTING APPLICATION SERVICES ==="
# Execute the service launcher
exec /start.sh