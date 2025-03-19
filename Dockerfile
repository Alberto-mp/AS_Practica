FROM php:8.4-fpm

# Instalar dependencias para GD
RUN apt-get update && apt-get install -y libpng-dev libjpeg-dev libfreetype6-dev && \
    docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd

# Instalar y habilitar OPcache
RUN docker-php-ext-install opcache

# Instalar las dependencias para PostgreSQL
RUN apt-get update && apt-get install -y libpq-dev && \
    docker-php-ext-install pdo_pgsql
