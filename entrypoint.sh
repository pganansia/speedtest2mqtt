#!/bin/bash
##################################################################
# Point d'entrée du conteneur : prépare la planification et lance
# crond (BusyBox, fourni par Alpine).
##################################################################
set -e

# Fréquence des tests : toutes les 3 heures, à la 17e minute.
# Ookla limite le nombre de tests par adresse IP : un test toutes
# les 5 minutes (288 par jour) déclenche l'erreur « Limit reached ».
CRON="${CRON:-17 */3 * * *}"

SCRIPT=/app/speedtest2mqtt.sh
RUN_DIR=/run/speedtest2mqtt
ENV_FILE="${RUN_DIR}/container.env"
mkdir -p "${RUN_DIR}" /config /etc/crontabs

##################################################################
# Anciennes versions : fichiers copiés dans /config, plus utilisés
##################################################################
if [[ -f /config/speedtest2mqtt.sh || -f /config/crontab.yml || -f /config/container.env ]]; then
    echo "Old files found in /config (speedtest2mqtt.sh, crontab.yml, container.env):"
    echo "they are no longer used and can be deleted (container.env may contain your MQTT password)."
fi

##################################################################
# crond ne transmet pas les variables du conteneur aux tâches :
# elles sont écrites dans un fichier lu avant chaque test.
# Uniquement les variables utiles, valeurs protégées par des
# apostrophes, fichier lisible par root seulement, hors du volume.
##################################################################
umask 077
: > "${ENV_FILE}"
while IFS='=' read -r name _; do
    value="${!name}"
    printf "export %s='%s'\n" "${name}" "${value//\'/\'\\\'\'}" >> "${ENV_FILE}"
done < <(env | grep -E '^(TZ|FILE_RESULT|MQTT_[A-Z_]+|RANDOM_DELAY|SPEEDTEST_[A-Z_]+)=')

##################################################################
# Planification : la sortie du test est envoyée vers le journal
# du conteneur (docker logs)
##################################################################
echo "${CRON} . ${ENV_FILE} && ${SCRIPT} > /proc/1/fd/1 2>&1" > /etc/crontabs/root

echo "starting cron (${CRON})"
exec crond -f -d 8
