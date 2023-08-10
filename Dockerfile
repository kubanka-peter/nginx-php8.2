FROM php:8.2-fpm as prod

# S6 Overlay
# s6 documentation: https://github.com/just-containers/s6-overlay
# execlin documentation (for #!/command/execlineb) : https://skarnet.org/software/execline/

ARG S6_OVERLAY_VERSION=3.1.5.0
ENV S6_KEEP_ENV=1
ENV S6_CMD_WAIT_FOR_SERVICES_MAXTIME=0

RUN apt-get update && apt-get install -y nginx xz-utils
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-noarch.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-noarch.tar.xz
ADD https://github.com/just-containers/s6-overlay/releases/download/v${S6_OVERLAY_VERSION}/s6-overlay-x86_64.tar.xz /tmp
RUN tar -C / -Jxpf /tmp/s6-overlay-x86_64.tar.xz
ENTRYPOINT ["/init"]

# php setup
RUN cp /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini \
    && mkdir -p /var/run/php \
    # gd
    && apt-get install -y --no-install-recommends libpng-dev libjpeg-dev libfreetype6-dev \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install gd \
    # mysql
    && docker-php-ext-install pdo_mysql \
    # postgre
    && apt-get install -y libpq-dev \
    && docker-php-ext-configure pgsql -with-pgsql=/usr/local/pgsql \
    && docker-php-ext-install pdo pdo_pgsql pgsql \
    # redis
    && pecl install -o -f redis \
    &&  rm -rf /tmp/pear \
    &&  docker-php-ext-enable redis \
    # intl
    && apt-get install -y zlib1g-dev libicu-dev g++ \
    && docker-php-ext-install intl \
    # opcache
    && docker-php-ext-install opcache \
    && mkdir -p /var/www/project/public \
    && echo "<?php phpinfo(); " >> /var/www/project/public/index.php

# install nginx
RUN apt-get install -y --no-install-recommends nginx \
    && rm -rf /etc/nginx/sites-enabled/* \
    && mv /etc/nginx/sites-available/default /etc/nginx/sites-available/default.conf \
    && ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf

# simple template, to build config files at runtime
COPY --from=hairyhenderson/gomplate:stable /gomplate /bin/gomplate

# PHP config
COPY php-config/prod /

# nginx config
COPY nginx-config/prod /

# s6 config
COPY s6-config/prod /

# clear
RUN apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# php ini override default config
ENV PHP_TIMEZONE="Europe/Budapest"
ENV PHP_UPLOAD_MAX_FILESIZE="16M"
ENV PHP_POST_MAX_SIZE="24M"
ENV PHP_MEMORY_LIMIT="48M"
ENV PHP_MAX_EXECUTION_TIME="30"
ENV PHP_OPCACHE_ENABLED="1"
ENV PHP_OPCACHE_MEMORY_CONSUMPTION="128M"
ENV PHP_OPCACHE_JIT_BUFFER_SIZE="64M"
ENV PHP_OPCACHE_JIT="tracing"
ENV PHP_OPCACHE_VALIDATE_TIMESTAMPS="1"
ENV PHP_OPCACHE_REVALIDATE_FREQ="0"

WORKDIR /var/www/project

EXPOSE 80

FROM prod AS dev

RUN apt-get update \
    # dev tools
    && apt-get install -y procps git vim-nox mc unzip inotify-tools \
    && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer \
    # change to dev php.ini
    && cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini \
    # install symfony bin \
    && curl -1sLf 'https://dl.cloudsmith.io/public/symfony/stable/setup.deb.sh' | bash \
    && apt-get update \
    && apt-get install symfony-cli

# PHP config
COPY php-config/dev /

# nginx config
COPY nginx-config/dev /

# s6 config
COPY s6-config/dev /

# in dev mode the www-data userId and groupId is modified to match the host user, \
# so you can mount the project folder and you dont have permission issues
ENV USER_ID=1000
ENV GROUP_ID=1000