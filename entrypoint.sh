#!/bin/bash
##################################################################
# Copie des fichiers de configuration vers /config
##################################################################
if [ ! -f "/config/crontab.yml" ]; then
    echo "Copying crontab.yml ..."
    cp /app/config/crontab.yml /config
fi
if [ ! -f "/config/speedtest2mqtt.sh" ]; then
    echo "Copying speedtest2mqtt.sh ..."
    cp /app/config/speedtest2mqtt.sh /config
fi

##################################################################
# Copie des fichiers de configuration vers /config
##################################################################
CRON=${CRON:-0 0,6,12,18 * * *}
declare | grep -Ev 'BASHOPTS|BASH_VERSINFO|EUID|PPID|SHELLOPTS|UID' > /config/container.env
sed -i "/schedule/c\    schedule: \"${CRON}\"" /config/crontab.yml
echo "starting cron (${CRON})"
/speedtest2mqtt/bin/yacron -c /config/crontab.yml
