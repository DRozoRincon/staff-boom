FROM composer:lts@sha256:37871d829df42604465e4f659564025ccd09f9ece73eb009e79185d01a80051b AS build

ARG APP_ENV=develop

COPY --from=mlocati/php-extension-installer:2.2.5@sha256:f9b2171089d4d90b48dd8309acb17220d5fadb1fe9e6550b95d92f28ab88fed1 /usr/bin/install-php-extensions /usr/local/bin/

RUN chmod +x /usr/local/bin/install-php-extensions

RUN install-php-extensions mongodb \
        redis \
        mysqli \
        pdo \
        pdo_mysql \
        zip \
        bcmath \
        gmp \
        openssl \
        mbstring \
        sodium \
        gd

COPY --chown=www-data:www-data ./src/composer.json ./src/composer.lock /app/

WORKDIR /app

RUN composer install --verbose --prefer-dist --no-interaction --no-scripts --optimize-autoloader --no-dev

COPY --chown=www-data:www-data ./src/artisan /app/artisan
COPY --chown=www-data:www-data ./src/server.php /app/server.php
COPY --chown=www-data:www-data ./src/bootstrap/ /app/bootstrap/
COPY --chown=www-data:www-data ./src/storage/ /app/storage/
COPY --chown=www-data:www-data ./src/public/ /app/public/
COPY --chown=www-data:www-data ./src/resources/ /app/resources/
COPY --chown=www-data:www-data ./src/database/ /app/database/
COPY --chown=www-data:www-data ./src/routes/ /app/routes/
COPY --chown=www-data:www-data ./src/report-times.sh /app/report-times.sh
COPY --chown=www-data:www-data ./src/Common/ /app/Common/
COPY --chown=www-data:www-data ./src/.env.${APP_ENV} /app/.env
COPY --chown=www-data:www-data ./src/config/ /app/config/
COPY --chown=www-data:www-data ./src/app/ /app/app/

RUN composer install --verbose --prefer-dist --no-interaction --optimize-autoloader --no-dev
RUN chown -R www-data:www-data /app/vendor

FROM php:8.2.15-cli-alpine3.19@sha256:2008ed7076d211961abef1c8628e23d364ba0a1a32d6d251f6fb10370eaefe70

ENV APP_DEBUG="true"

COPY --from=mlocati/php-extension-installer:2.2.5@sha256:f9b2171089d4d90b48dd8309acb17220d5fadb1fe9e6550b95d92f28ab88fed1 /usr/bin/install-php-extensions /usr/local/bin/
RUN chmod +x /usr/local/bin/install-php-extensions

RUN install-php-extensions mongodb \
        redis \
        mysqli \
        pdo \
        pdo_mysql \
        zip \
        bcmath \
        gmp \
        openssl \
        mbstring \
        sodium \
        gd

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

WORKDIR /var/www/html/
COPY --from=build /usr/bin/composer /usr/bin/composer
COPY --from=build /app/ /var/www/html/

CMD ["php", "-S", "0.0.0.0:80", "/var/www/html/public/index.php"]