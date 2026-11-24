#!/bin/bash
##################################################################
# speedtest2mqtt : lance un test Ookla Speedtest et publie les
# résultats sur un broker MQTT.
##################################################################
set -o pipefail

##################################################################
# Variables d'environnement et valeurs par défaut
##################################################################
FILE_RESULT="${FILE_RESULT:-/config/ookla.json}"
MQTT_HOST="${MQTT_HOST:-localhost}"
MQTT_PORT="${MQTT_PORT:-1883}"
MQTT_ID="${MQTT_ID:-speedtest2mqtt}"
MQTT_TOPIC="${MQTT_TOPIC:-speedtest}"
MQTT_OPTIONS="${MQTT_OPTIONS:--r}"
MQTT_USER="${MQTT_USER:-}"
MQTT_PASS="${MQTT_PASS:-}"
# Délai aléatoire maximal (secondes) avant le test : évite que tous les
# utilisateurs interrogent les serveurs Ookla à la même seconde
RANDOM_DELAY="${RANDOM_DELAY:-60}"
# Identifiant de serveur Ookla imposé (vide = choix automatique)
SPEEDTEST_SERVER_ID="${SPEEDTEST_SERVER_ID:-}"
TIMESTAMP="$(date -Iseconds)"

log() {
    echo "$(date -Iseconds) $*"
}

##################################################################
# Publication MQTT d'une valeur : publish <sous-topic> <valeur>
##################################################################
publish() {
    local args=(-h "${MQTT_HOST}" -p "${MQTT_PORT}" -i "${MQTT_ID}" -t "${MQTT_TOPIC}/$1" -m "$2")
    [[ -n "${MQTT_USER}" ]] && args+=(-u "${MQTT_USER}")
    [[ -n "${MQTT_PASS}" ]] && args+=(-P "${MQTT_PASS}")
    # MQTT_OPTIONS est volontairement découpé en plusieurs options (ex. "-r -q 1")
    # shellcheck disable=SC2206
    args+=(${MQTT_OPTIONS})
    if ! /usr/bin/mosquitto_pub "${args[@]}"; then
        log "MQTT publish failed for topic ${MQTT_TOPIC}/$1"
        return 1
    fi
}

log "Starting speedtest"
log "Result file: ${FILE_RESULT}"

##################################################################
# Délai aléatoire
##################################################################
if [[ "${RANDOM_DELAY}" =~ ^[0-9]+$ ]] && (( RANDOM_DELAY > 0 )); then
    delay=$(( RANDOM % (RANDOM_DELAY + 1) ))
    log "Waiting ${delay} s before running the test"
    sleep "${delay}"
fi

##################################################################
# Lancement de speedtest
# Le résultat est écrit dans un fichier temporaire : le fichier final
# n'est remplacé que si le test a réussi.
##################################################################
tmp_result="$(mktemp)"
tmp_error="$(mktemp)"
trap 'rm -f "${tmp_result}" "${tmp_error}"' EXIT

speedtest_args=(--accept-license --accept-gdpr -f json-pretty)
[[ -n "${SPEEDTEST_SERVER_ID}" ]] && speedtest_args+=(--server-id="${SPEEDTEST_SERVER_ID}")

speedtest "${speedtest_args[@]}" > "${tmp_result}" 2> "${tmp_error}"
rc=$?

##################################################################
# Gestion des erreurs : code retour, message sur stderr, ou champ
# « error » dans le JSON
##################################################################
json_error="$(jq -r '.error // empty' "${tmp_result}" 2>/dev/null)"
if (( rc != 0 )) || [[ -n "${json_error}" ]] || ! jq -e '.download.bandwidth' "${tmp_result}" > /dev/null 2>&1; then
    message="${json_error:-$(grep -v '^[[:space:]]*$' "${tmp_error}" | tail -n 1)}"
    message="${message:-speedtest exit code ${rc}}"
    log "Process error       = ${message}"
    publish status "error"
    publish error "${message}"
    log "Ending speedtest"
    exit 1
fi
log "Process error       = No error"
mv "${tmp_result}" "${FILE_RESULT}"

##################################################################
# Récupération des résultats
##################################################################
j() { jq -r "$1" "${FILE_RESULT}"; }
timestamp="$(j '.timestamp')"
jitter="$(j '.ping.jitter')"
ping="$(j '.ping.latency')"
# bande passante en octets/s -> Mbit/s
download="$(j '(.download.bandwidth * 8 / 1000000 * 100 | round) / 100')"
upload="$(j '(.upload.bandwidth * 8 / 1000000 * 100 | round) / 100')"
isp="$(j '.isp')"
interfaceinternalip="$(j '.interface.internalIp')"
interfacename="$(j '.interface.name')"
interfacemacaddr="$(j '.interface.macAddr')"
interfaceisvpn="$(j '.interface.isVpn')"
interfaceexternalip="$(j '.interface.externalIp')"
servername="$(j '.server.name')"
servercountry="$(j '.server.country')"
serverlocation="$(j '.server.location')"
serverhost="$(j '.server.host')"
serverport="$(j '.server.port')"
serverip="$(j '.server.ip')"
resultid="$(j '.result.id')"
resulturl="$(j '.result.url')"

##################################################################
# Affichage des résultats
##################################################################
log "timestamp           = ${timestamp}"
log "jitter              = ${jitter} ms"
log "ping                = ${ping} ms"
log "download            = ${download} Mbps"
log "upload              = ${upload} Mbps"
log "isp                 = ${isp}"
log "interfacename       = ${interfacename}"
log "servername          = ${servername}"
log "serverlocation      = ${serverlocation}"
log "resulturl           = ${resulturl}"
log "sending results to ${MQTT_HOST}:${MQTT_PORT} as clientID ${MQTT_ID} with options ${MQTT_OPTIONS}"

##################################################################
# Envoi des valeurs vers MQTT (mêmes topics que les versions
# précédentes, plus status, error et last_run)
##################################################################
failed=0
publish timestamp "${timestamp}" || failed=1
publish jitter "${jitter}" || failed=1
publish ping "${ping}" || failed=1
publish download "${download}" || failed=1
publish upload "${upload}" || failed=1
publish isp "${isp}" || failed=1
publish interface/internalip "${interfaceinternalip}" || failed=1
publish interface/name "${interfacename}" || failed=1
publish interface/macaddr "${interfacemacaddr}" || failed=1
publish interface/isvpn "${interfaceisvpn}" || failed=1
publish interface/externalip "${interfaceexternalip}" || failed=1
publish server/name "${servername}" || failed=1
publish server/location "${serverlocation}" || failed=1
publish server/country "${servercountry}" || failed=1
publish server/host "${serverhost}" || failed=1
publish server/port "${serverport}" || failed=1
publish server/ip "${serverip}" || failed=1
publish result/id "${resultid}" || failed=1
publish result/url "${resulturl}" || failed=1
publish status "ok" || failed=1
publish error "" || failed=1
publish last_run "${TIMESTAMP}" || failed=1

log "Ending speedtest"
exit "${failed}"
