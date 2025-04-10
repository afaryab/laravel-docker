
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ondrej/php && apt-get update
    
RUN apt-get update -y && apt upgrade -y && apt-get install -y --force-yes --no-install-recommends \
    build-essential \
    php8.3 \
    php8.3-fpm \
    php8.3-cli \
    php-pear \
    php-dev \
    nginx \
    libmemcached-dev \
    libfcgi-bin \
    libzip-dev \
    libz-dev \
    libzip-dev \
    libpq-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libssl-dev \
    libvips-dev \
    openssh-server \
    libmagickwand-dev \
    git \
    cron \
    nano \
    libxml2-dev \
    libreadline-dev \
    libgmp-dev \
    mariadb-client \
    unzip \
    build-essential \
    iputils-ping \
    gcc \
    g++ \
    make \
    autoconf \
    automake \
    libtool \
    python3 python3-pip \
    nasm \
    openssl \
    curl \
    sqlite3 \
    libsqlite3-dev tar ca-certificates
    
RUN apt-get install -y --no-install-recommends \
    php8.3-bcmath \
    php8.3-curl \
    php8.3-mbstring \
    php8.3-mysql \
    php8.3-tokenizer \
    php8.3-xml \
    php8.3-zip \
    php8.3-soap \
    php8.3-exif \
    php8.3-opcache \
    php8.3-gd \
    php8.3-intl \
    php8.3-gmp \
    php8.3-pgsql \
    php8.3-sqlite3 \
    php8.3-cli

RUN echo "zend_extension=opcache.so" > /etc/php/8.3/cli/conf.d/10-opcache.ini && \
    echo "opcache.enable=1" >> /etc/php/8.3/cli/conf.d/10-opcache.ini && \
    echo "opcache.enable_cli=1" >> /etc/php/8.3/cli/conf.d/10-opcache.ini && \
    echo "opcache.memory_consumption=128" >> /etc/php/8.3/cli/conf.d/10-opcache.ini && \
    echo "opcache.max_accelerated_files=4000" >> /etc/php/8.3/cli/conf.d/10-opcache.ini && \
    echo "opcache.validate_timestamps=1" >> /etc/php/8.3/cli/conf.d/10-opcache.ini

RUN echo "soap.wsdl_cache_dir=/tmp" > /etc/php/8.3/cli/conf.d/20-soap.ini

RUN echo "exif.decode_unicode_motorola=1" > /etc/php/8.3/cli/conf.d/20-exif.ini

RUN echo "extension=exif" > /etc/php/8.3/cli/conf.d/20-exif.ini

RUN pear config-set php_ini /etc/php/8.3/fpm/php.ini

#####################################
# Composer:
#####################################

# Install composer and add its bin to the PATH.
RUN curl -s http://getcomposer.org/installer | php && \
    echo "export PATH=${PATH}:/var/www/vendor/bin" >> ~/.bashrc && \
    mv composer.phar /usr/local/bin/composer
# Source the bash
RUN . ~/.bashrc

#####################################
# Laravel Supervisor:
#####################################

RUN apt-get install -y supervisor


#####################################
# NODE JS & YARN:
#####################################

RUN curl -sL https://deb.nodesource.com/setup_20.x | bash -

RUN apt-get install -y nodejs

RUN npm install -g npm@11.1.0

RUN npm install -g yarn

RUN yarn init -y
RUN yarn cache clean
RUN yarn set version 4.1.1

RUN npm install -g pnpm

# Setup pnpm environment
ENV PNPM_HOME="/root/.local/share/pnpm"
ENV PATH="$PNPM_HOME:$PATH"

RUN apt-get update -y update && apt-get certbot python3-certbot-apache -y

RUN apt-get autoremove -y && apt-get clean && rm -rf /var/lib/apt/lists/* || true
