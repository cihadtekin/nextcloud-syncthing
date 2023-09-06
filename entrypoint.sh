#!/bin/sh
set -ex

# Create directories
[ ! -d $NEXTCLOUD_DIR ] && mkdir -p $NEXTCLOUD_DIR
[ ! -d $NEXTCLOUD_DATA_DIR ] && mkdir -p $NEXTCLOUD_DATA_DIR
[ ! -d $SYNCTHING_DIR ] && mkdir -p $SYNCTHING_DIR

# Create the user
if ! getent passwd user > /dev/null 2>&1; then
  addgroup -g $GROUP_ID user
  id -u user &>/dev/null || adduser -s /bin/sh -D -H -u $USER_ID -G user user
fi

# ======= NEXTCLOUD =======
TEST_FILE="${NEXTCLOUD_DIR}/config/config.php"

if [ ! -f $TEST_FILE ]; then
  # Setup
  php $NEXTCLOUD_INSTALLATION_DIR/occ maintenance:install \
    -n \
    --admin-user $NEXTCLOUD_ADMIN_USER \
    --admin-pass $NEXTCLOUD_ADMIN_PASS \
    --admin-email $NEXTCLOUD_ADMIN_EMAIL \
    --data-dir $NEXTCLOUD_DATA_DIR \
    --database "sqlite" \
    --database-name "database.sqlite"

  # Add necessary lines to Nextcloud config
  export NEXTCLOUD_DOMAIN=$(echo $NEXTCLOUD_URL | sed -E "s/^https?:\/\///")

  php $NEXTCLOUD_INSTALLATION_DIR/occ config:system:set defaultapp --value="files"
  php $NEXTCLOUD_INSTALLATION_DIR/occ config:system:set filesystem_check_changes --value="1" --type="integer"
  php $NEXTCLOUD_INSTALLATION_DIR/occ config:system:set trusted_domains 1 --value="${NEXTCLOUD_DOMAIN}"

  # Install and enable default apps
  php $NEXTCLOUD_INSTALLATION_DIR/occ app:install unroundedcorners
  php $NEXTCLOUD_INSTALLATION_DIR/occ app:install spreed

  # Move all the files to the correct location
  mv $NEXTCLOUD_INSTALLATION_DIR/* $NEXTCLOUD_DIR
fi


# ======= SYNCTHING =======
SUPERVISOR_CONF=/usr/local/etc/supervisor.conf
SYNCTHING_CONF=$SYNCTHING_DIR/.config/syncthing/config.xml

# Supervisor config
echo "[supervisord]
nodaemon=false
logfile=/tmp/supervisord.log
pidfile=/tmp/supervisord.pid

[unix_http_server]
file=/tmp/supervisor.sock
chmod=0700

[rpcinterface:supervisor]
supervisor.rpcinterface_factory=supervisor.rpcinterface:make_main_rpcinterface

[supervisorctl]
serverurl=unix:///tmp/supervisor.sock

[program:syncthing]
autorestart = True
directory = ${SYNCTHING_DIR}/
user = user
command = /usr/bin/syncthing --no-browser --home=\"${SYNCTHING_DIR}/.config/syncthing\"
environment = STNORESTART=\"1\", HOME=\"${SYNCTHING_DIR}\"" > $SUPERVISOR_CONF

# Ownership correction
chown -R user:user \
  $NEXTCLOUD_DIR \
  $NEXTCLOUD_DATA_DIR \
  $SYNCTHING_DIR \
  $SUPERVISOR_CONF

# "user" doesn't have permissions to write to docker's STDOUT (for php-fpm)
chmod 0777 /proc/self/fd/2

# Start supervisord
if [ -f $SYNCTHING_CONF  ]; then
  su -c "supervisord -c ${SUPERVISOR_CONF}" user
else
  # First, we start syncthing and wait for it's config file to be created
  su -c "supervisord -c ${SUPERVISOR_CONF}" user
  until [ -f $SYNCTHING_CONF ]; do
    sleep 2
  done
  # Update syncthing config file and restart syncthing
  sed -i "s/127\.0\.0\.1/0.0.0.0/" $SYNCTHING_CONF
  su -c "supervisorctl -c ${SUPERVISOR_CONF} restart syncthing" user
fi

# start php-fpm
su -c "$@" user
