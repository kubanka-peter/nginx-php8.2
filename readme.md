Nginx - PHP 8.2 FPM with S6 Overlay
===================================

- Symfony ready
- GD and INTL libraries are installed
- Supported databases: `mysql`, `pgsql`, `redis`
- Opcache is enabled by default.

## Simple usage in docker-compose.yml

```
version: '3.7'
services:
    example:
        image: kubi84/nginx-php8.2:dev
        volumes:
            - "./:/var/www/project/"
```

For production use the `kubi84/nginx-php8.2` image.

See a full exmaple at: https://github.com/kubanka-peter/nginx-php8.2-example

## Adding another services, such as cron etc.

This image is using s6-overlay, it's a process supervisor and init system for containers. Documentation: https://github.com/just-containers/s6-overlay
Also see the `s6-config` folder.

## You can change some php.ini settings via environment variables:

```
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
```

If you want to override more php settings, you can do it in the `php-config/prod/usr/local/etc/php/conf.d.templates/99-overrides.ini` file.
This file is compiled at the container startup.

## DEV image

The dev image is based on the prod image, but it has some additional tools:

- `ps`, `git`, `vim`, `mc`, `zip`, `inotify`
- `composer`, `symfony-cli`
- dev php.ini settings is used
- you can change the www-data user id and group id via environment variables, so you can use the same user id on your host machine and in the container, preventing permission issues.

```
ENV USER_ID=1000
ENV GROUP_ID=1000
```