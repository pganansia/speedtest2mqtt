#!/bin/bash
MQTT_HOST=${MQTT_HOST:-localhost}
MQTT_ID=${MQTT_ID:-speedtest2mqtt}
MQTT_TOPIC=${MQTT_TOPIC:-speedtest}
MQTT_OPTIONS=${MQTT_OPTIONS:-"-r"}
MQTT_USER=${MQTT_USER:-user}
MQTT_PASS=${MQTT_PASS:-pass}
TIMESTAMP=$(date -Iseconds)

#############################################
# Si vous souhaitez debugger le fichier
# ookla.json, il suffit de remplacer la
# variable file par
# file=/config/${TIMESTAMP}_ookla.json.
# Ainsi vous ^puvez editer le fichier.
#############################################
#file=/config/ookla.json
file=/config/${TIMESTAMP}_ookla.json                                                                                      

#############################################
# Lancement du traitement.
#############################################
echo "${file} : ookla.json path"
echo "${TIMESTAMP} starting speedtest"
echo "${TIMESTAMP} starting speedtest"

#############################################
# Lancement de speedtest.
#############################################                                                                                      
speedtest --accept-license --accept-gdpr -f json-pretty > ${file}

#############################################
# Test d'un resultat en erreur.
#############################################
ERROR=$(jq -r '.error' ${file})
if [ -z "$ERROR" ]
then
    echo "${TIMESTAMP} error in results"
    exit;
fi

#############################################
# Création des valeurs à envoyer.
#############################################
downraw=$(jq -r '.download.bandwidth' ${file})
download=$(printf %.2f\\n "$((downraw * 8))e-6")
upraw=$(jq -r '.upload.bandwidth' ${file})
upload=$(printf %.2f\\n "$((upraw * 8))e-6")
ping=$(jq -r '.ping.latency' ${file})
jitter=$(jq -r '.ping.jitter' ${file})
packetloss=$(jq -r '.packetLoss' ${file})
serverid=$(jq -r '.server.id' ${file})
servername=$(jq -r '.server.name' ${file})
servercountry=$(jq -r '.server.country' ${file})
serverlocation=$(jq -r '.server.location' ${file})
serverhost=$(jq -r '.server.host' ${file})
timestamp=$(jq -r '.timestamp' ${file})

#############################################                    
# Inscription dans la log.                         
#############################################                                                                                      
echo "${TIMESTAMP} speedtest results"
echo "${TIMESTAMP} download = ${download} Mbps"
echo "${TIMESTAMP} upload =  ${upload} Mbps"
echo "${TIMESTAMP} ping =  ${ping} ms"
echo "${TIMESTAMP} jitter = ${jitter} ms"
echo "${TIMESTAMP} sending results to ${MQTT_HOST} as clientID ${MQTT_ID} with options ${MQTT_OPTIONS} using user ${MQTT_USER}"

#############################################                    
# Envoie des valeurs vers MQTT.                         
#############################################                                                                                      
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/download -m "${download}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/upload -m "${upload}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/ping -m "${ping}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/jitter -m "${jitter}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/packetloss -m "${packetloss}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/server/id -m "${serverid}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/server/name -m "${servername}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/server/location -m "${serverlocation}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/server/host -m "${serverhost}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/server/country -m "${servercountry}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/timestamp -m "${timestamp}"
