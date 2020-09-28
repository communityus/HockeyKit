#!/bin/sh

set -e

echo "Got here!"

# link all applications from /hockey_data to /var/www/html/public
for app in $(find /hockey_data/ -maxdepth 1 -type d -not -path /hockey_data/); do
  ln -s "$app" /var/www/html/public/
done


/usr/bin/supervisord -c /etc/supervisor/conf.d/supervisord.conf