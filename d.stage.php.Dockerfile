FROM php:7.4-fpm

# Install dependencies
RUN apt-get update && apt-get install -y \
    # build-essential \
    # libpng-dev \
    libjpeg62-turbo-dev \
    libfreetype6-dev \
    # locales \
    zip \
    unzip
# jpegoptim optipng pngquant gifsicle \
# vim
# git \
# curl
#remove vim in production

# Clear cache
RUN apt-get clean && rm -rf /var/lib/apt/lists/*

RUN docker-php-ext-install -j$(nproc) pdo pdo_mysql
RUN docker-php-ext-configure gd --with-freetype --with-jpeg
RUN docker-php-ext-install gd

ENV \
    APP_DIR="/var/www"

# Copy composer.lock and composer.json
COPY composer.lock composer.json ${APP_DIR}/
# COPY composer.lock ${APP_DIR}/

# Set working directory
WORKDIR ${APP_DIR}


# RUN php dismod xdebug

# RUN curl -sS https://getcomposer.org/installer | php \
#     && mv composer.phar /usr/local/bin/composer

RUN php -r "readfile('http://getcomposer.org/installer');" | php -- --install-dir=/usr/bin/ --filename=composer

# RUN curl -sS https://getcomposer.org/installer | php && mv composer.phar /usr/local/bin/composer
RUN composer global require hirak/prestissimo --no-plugins --no-scripts

RUN composer install --prefer-dist --no-scripts --optimize-autoloader  && rm -rf /root/.composer
# RUN composer install --prefer-dist --no-scripts --no-autoloader  && rm -rf /root/.composer
# RUN composer install --prefer-dist --no-scripts --no-dev --no-autoloader && rm -rf /root/.composer
# RUN composer dump-autoload --no-scripts --no-dev --optimize


# Finish composer
# RUN composer dump-autoload --no-scripts  --optimize
# RUN composer dump-autoload --no-scripts --no-dev --optimize

# Copy existing application directory contents
COPY . /var/www

# Add user for laravel application
RUN groupadd -g 1000 www
RUN useradd -u 1000 -ms /bin/bash -g www www

# Copy existing application directory permissions
COPY --chown=www:www . /var/www

# Give laravel permission to storage folder
RUN chmod -R 775 storage

RUN cp .env.example .env
RUN touch ./database/database.sqlite

ENV \
    APP_PORT="9000" \
    APP_ENV="production" \
    APP_DEBUG=true

RUN echo "ENV VARIABLE"
RUN echo ${DB_HOST1}
RUN echo ${ENV2}

RUN composer dump-autoload --no-scripts  --optimize
RUN php artisan package:discover
RUN yes | php artisan migrate:refresh --seed

RUN php artisan key:generate
RUN php artisan jwt:secret
RUN php artisan route:cache && php artisan config:cache && php artisan view:cache

# Finish composer
RUN composer dump-autoload --no-scripts --optimize
# RUN composer dump-autoload --no-scripts --no-dev --optimize

# Change current user to www
USER www

EXPOSE ${APP_PORT}

# COPY wait-for-it.sh ./wait-for-it.sh
# RUN chmod +x ./wait-for-it.sh && echo "Waiting for MySQL"
# RUN  echo "Waiting for MySQL"
# RUN php artisan serve --host=0.0.0.0 --port=9000
CMD php artisan serve --host=0.0.0.0 --port=${APP_PORT}
# RUN ./wait-for-it.sh --timeout=0 iiitrMysql:3306 -- php artisan serve --host=0.0.0.0 --port=9000

# Expose port 9000 and start php-fpm server
# CMD ["php-fpm"]
