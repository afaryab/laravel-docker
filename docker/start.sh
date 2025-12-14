#!/bin/sh

echo "Starting Laravel application services..."

# Create log directories for supervisor
mkdir -p /var/log/supervisor

# Verify supervisord config exists
if [ ! -f "/etc/supervisor/conf.d/supervisord.conf" ]; then
    echo "ERROR: supervisord.conf not found!"
    exit 1
fi

echo "AUTH setting: ${AUTH:-none}"
echo "Starting supervisor (nginx, php-fpm, workers, cron)..."

# Start supervisor which manages all services
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf
