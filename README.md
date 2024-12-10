# laravel-docker

A Docker Image for my laravel projects you can create your image with below Dockerfile

```yaml
FROM ahmadfaryabkokab/laravel-docker:latest

ENV COMPOSER_MEMORY_LIMIT='-1'

#####################################
# Laravel Schedule Cron Job:
#####################################

RUN echo "* * * * * www-data /usr/local/bin/php /var/www/artisan schedule:run >> /dev/null 2>&1"  >> /etc/cron.d/laravel-scheduler
RUN chmod 0644 /etc/cron.d/laravel-scheduler


#
#--------------------------------------------------------------------------
# Final Touch
#--------------------------------------------------------------------------
#

ADD ./docker/laravel.ini /usr/local/etc/php/conf.d

RUN yarn init -2
RUN yarn set version 4.1.1

#####################################
# Aliases:
#####################################
# docker-compose exec php-fpm dep --> locally installed Deployer binaries
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/vendor/bin/dep "$@"' > /usr/bin/dep
RUN chmod +x /usr/bin/dep
# docker-compose exec php-fpm art --> php artisan
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/artisan "$@"' > /usr/bin/art
RUN chmod +x /usr/bin/art
# docker-compose exec php-fpm migrate --> php artisan migrate
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/artisan migrate "$@"' > /usr/bin/migrate
RUN chmod +x /usr/bin/migrate
# docker-compose exec php-fpm fresh --> php artisan migrate:install --seed
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/artisan migrate:install --seed' > /usr/bin/fresh
RUN chmod +x /usr/bin/fresh
# docker-compose exec php-fpm refresh --> php artisan migrate:fresh --seed
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/artisan migrate:fresh --seed' > /usr/bin/refresh
RUN chmod +x /usr/bin/refresh
# docker-compose exec php-fpm t --> run the tests for the project and generate testdox
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/artisan config:clear\n/var/www/vendor/bin/phpunit -d memory_limit=2G --stop-on-error --stop-on-failure --testdox-text=tests/report.txt "$@"' > /usr/bin/t
RUN chmod +x /usr/bin/t
# docker-compose exec php-fpm d --> run the Laravel Dusk browser tests for the project
RUN echo '#!/bin/bash\n/usr/local/bin/php /var/www/artisan config:clear\n/bin/bash\n/usr/local/bin/php /var/www/artisan dusk -d memory_limit=2G --stop-on-error --stop-on-failure --testdox-text=tests/report-dusk.txt "$@"' > /usr/bin/d
RUN chmod +x /usr/bin/d

RUN rm -r /var/lib/apt/lists/*

RUN usermod -u 1000 www-data

WORKDIR /var/www

# COPY --chown=www-data:www-data ../ /var/www
COPY . /var/www
ADD docker/supervisord.conf /etc/supervisor/conf.d/worker.conf
COPY ./docker/docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh
RUN ln -s /usr/local/bin/docker-entrypoint.sh /
ENTRYPOINT ["docker-entrypoint.sh"]


USER root

RUN rm /usr/local/etc/php-fpm.d/docker.conf \
    && rm /usr/local/etc/php-fpm.d/www.conf \
    && rm /usr/local/etc/php-fpm.d/www.conf.default \
    && rm /usr/local/etc/php-fpm.d/zz-docker.conf

ADD ./docker/php/php-fpm.d/docker.conf /usr/local/etc/php-fpm.d/docker.conf
ADD ./docker/php/php-fpm.d/www.conf /usr/local/etc/php-fpm.d/www.conf
ADD ./docker/php/php-fpm.d/www.conf.default /usr/local/etc/php-fpm.d/www.conf.default
ADD ./docker/php/php-fpm.d/zz-docker.conf /usr/local/etc/php-fpm.d/zz-docker.conf


#####################################
# YARN Setup:
#####################################

# Install Laravel Mix globally
RUN npm install -g laravel-mix webpack laravel-vite-plugin vite
RUN npm install -D webpack-cli
RUN yarn
RUN yarn build

EXPOSE 8001

CMD ["php-fpm"]

```