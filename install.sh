#!/bin/sh
set -ex

# Install/configure dependencies
apk add --no-cache --virtual .build-deps \
  syncthing \
  supervisor \
  bzip2 \
  gnupg \
  autoconf \
  freetype-dev \
  gmp-dev \
  icu-dev \
  libevent-dev \
  libjpeg-turbo-dev \
  libmcrypt-dev \
  libpng-dev \
  libwebp-dev \
  libxml2-dev \
  libzip-dev \
  openldap-dev \
  pcre-dev

docker-php-ext-configure gd --with-freetype --with-jpeg --with-webp
docker-php-ext-configure ldap

docker-php-ext-install -j "$(nproc)" \
  bcmath \
  exif \
  gd \
  gmp \
  intl \
  ldap \
  pcntl \
  sysvsem \
  zip

PHP_MEMORY_LIMIT="4096M"
PHP_UPLOAD_LIMIT="4096M"

# Create directories
[ ! -d $NEXTCLOUD_INSTALLATION_DIR ] && mkdir -p $NEXTCLOUD_INSTALLATION_DIR

# Nextcloud requirements for php
echo "memory_limit=${PHP_MEMORY_LIMIT}
upload_max_filesize=${PHP_UPLOAD_LIMIT}
post_max_filesize=${PHP_UPLOAD_LIMIT}" > "${PHP_INI_DIR}/conf.d/nextcloud.ini"

# Download nextcloud
curl -fsSL -o nextcloud.tar.bz2 "https://download.nextcloud.com/server/releases/nextcloud-${NEXTCLOUD_VERSION}.tar.bz2"

# Extract the source
tar --strip-components=1 -xjf nextcloud.tar.bz2 -C "${NEXTCLOUD_INSTALLATION_DIR}/"

# Clean up
rm nextcloud.tar.bz2
rm -rf "${NEXTCLOUD_INSTALLATION_DIR}/updater"

