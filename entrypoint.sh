#!/bin/bash
##################################################################
# Point d'entrée du conteneur : prépare la planification yacron
# puis la lance.
##################################################################
set -e

# Fréquence des tests : toutes les 3 heures, à la 17e minute.
# Ookla limite le nombre de tests par adresse IP : un test toutes
# les 5 minutes (288 par jour) déclenche l'erreur « Limit reached ».
CRON="${CRON:-17 */3 * * *}"

APP_DIR=/app/config
RUN_DIR=/run/speedtest2mqtt
mkdir -p "${RUN_DIR}" /config

##################################################################
# Ancienne version : le script était copié dans /config et cette
# copie n'était jamais mise à jour. Le script de l'image est
# désormais toujours utilisé.
##################################################################
if [[ -f /config/speedtest2mqtt.sh || -f /config/crontab.yml || -f /config/container.env ]]; then
    echo "Old files found in /config (speedtest2mqtt.sh, crontab.yml, container.env):"
    echo "they are no longer used and can be deleted (container.env may contain your MQTT password)."
fi

##################################################################
# Variables transmises au script : uniquement celles qui le
# concernent, dans un fichier lisible par root seulement et non
# persistant (pas dans le volume /config).
##################################################################
umask 077
env | grep -E '^(TZ|FILE_RESULT|MQTT_[A-Z_]+|RANDOM_DELAY|SPEEDTEST_[A-Z_]+)=' > "${RUN_DIR}/container.env" || true

##################################################################
# Planification
##################################################################
sed "s|__SCHEDULE__|${CRON}|; s|__SCRIPT__|${APP_DIR}/speedtest2mqtt.sh|; s|__ENV_FILE__|${RUN_DIR}/container.env|" \
    "${APP_DIR}/crontab.yml" > "${RUN_DIR}/crontab.yml"

echo "starting cron (${CRON})"
exec /speedtest2mqtt/bin/yacron -c "${RUN_DIR}/crontab.yml"
