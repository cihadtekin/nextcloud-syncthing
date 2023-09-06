# nextcloud-syncthing
Combines Nextcloud and Syncthing in a single Docker image. This image makes it possible to run both software with a non-root user to avoid permission issues.

## Example build
```sh
$ docker build -t nextcloud-syncthing .
```

## Example run
```sh
$ docker run \
  -d \
  -p 9000:9000 \
  -p 8384:8384 \
  -p 22000:22000 \
  -p 22000:22000/udp \
  -p 21027:21027/udp \
  -e USER_ID="1000" \
  -e GROUP_ID="1000" \
  -e NEXTCLOUD_ADMIN_USER="nextcloudadmin" \
  -e NEXTCLOUD_ADMIN_PASS="nextcloudadminpassword" \
  -e NEXTCLOUD_ADMIN_EMAIL="adminemail" \
  -e NEXTCLOUD_URL="https://nextcloud.fqdn.com" \
  -v /var/www/html/nextcloud:/var/www/html/nextcloud \
  -v /data:/data \
  -v /home/user/syncthing:/usr/local/syncthing \
  nextcloud-syncthing

````

