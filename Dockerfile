
FROM ubuntu:20.04

RUN apt-get update && apt-get install -y software-properties-common && \
    add-apt-repository -y ppa:ondrej/php && apt-get update

RUN apt-get update && apt-get install -y --force-yes --no-install-recommends \
    build-essential \
    php8.3 \
    php8.3-fpm \
    php8.3-cli \
    php-pear \
    php-dev \
    nginx \
    libmemcached-dev \
    libzip-dev \
    libz-dev \
    libzip-dev \
    libpq-dev \
    libjpeg-dev \
    libpng-dev \
    libfreetype6-dev \
    libssl-dev \
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
    nodejs \
    npm

RUN pear config-set php_ini /etc/php/8.3/fpm/php.ini

RUN apt-get install openssl php8.3-bcmath php8.3-curl php8.3-json php8.3-mbstring php8.3-mysql php8.3-tokenizer php8.3-xml php8.3-zip

# # Install soap extention
# RUN docker-php-ext-install soap

# # Install for image manipulation
# RUN docker-php-ext-install exif

# # Install the PHP pcntl extention
# RUN docker-php-ext-install pcntl

# # Install the PHP zip extention
# RUN docker-php-ext-install zip

# # Install the PHP pdo_mysql extention
# RUN docker-php-ext-install pdo_mysql

# # Install the PHP pdo_pgsql extention
# RUN docker-php-ext-install pdo_pgsql

# # Install the PHP bcmath extension
# RUN docker-php-ext-install bcmath

# # Install the PHP intl extention
# RUN docker-php-ext-install intl

# # Install the PHP gmp extention
# RUN docker-php-ext-install gmp

# #####################################
# # GD:
# #####################################

# # Install the PHP gd library
# RUN docker-php-ext-install gd && \
#     docker-php-ext-configure gd --with-freetype --with-jpeg && \
#     docker-php-ext-install gd

# #####################################
# # xDebug:
# #####################################

# # Install the xdebug extension
# RUN pecl install xdebug

# #####################################
# # PHP Memcached:
# #####################################

# # Install the php memcached extension
# RUN pecl install memcached && docker-php-ext-enable memcached

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

RUN npm install --global yarn

RUN yarn init -2
RUN yarn set version 4.1.1