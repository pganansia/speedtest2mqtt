#!/bin/bash
#############################################
# Test et valeur par défault des variables
# d'environnement.
#############################################
FILE_RESULT=${FILE_RESULT:-/config/ookla.json}
MQTT_HOST=${MQTT_HOST:-localhost}
MQTT_ID=${MQTT_ID:-speedtest2mqtt}
MQTT_TOPIC=${MQTT_TOPIC:-speedtest}
MQTT_OPTIONS=${MQTT_OPTIONS:-"-r"}
MQTT_USER=${MQTT_USER:-user}
MQTT_PASS=${MQTT_PASS:-pass}
TIMESTAMP=$(date -Iseconds)

#############################################
# Lancement du traitement.
#############################################
echo "${TIMESTAMP} Starting speedtest"
echo "${TIMESTAMP} Result file: ${file}"

#############################################
# Lancement de speedtest.
#############################################                                                                                      
speedtest --accept-license --accept-gdpr -f json-pretty > ${FILE_RESULT}

#############################################
# Test d'un resultat en erreur.
#############################################
nberror=$(jq -r '.error' ${FILE_RESULT} | wc -w)
echo "${TIMESTAMP} Erreur de traitement nb mots: ${nberror}"
if [ ${nberror} -gt 1 ]; then
    echo "${TIMESTAMP} error in results";
    exit;
fi

#############################################
# Recuperation des resultats.
#############################################
timestamp=$(jq -r '.timestamp' ${FILE_RESULT})
jitter=$(jq -r '.ping.jitter' ${FILE_RESULT})
ping=$(jq -r '.ping.latency' ${FILE_RESULT})
download=$(printf %.2f\\n "$(($(jq -r '.download.bandwidth' ${FILE_RESULT}) * 8))e-6")
upload=$(printf %.2f\\n "$(($(jq -r '.upload.bandwidth' ${FILE_RESULT}) * 8))e-6")
isp=$(jq -r '.isp' ${FILE_RESULT})                                                    
interfaceinternalip=$(jq -r '.interface.internalIp' ${FILE_RESULT})                   
interfacename=$(jq -r '.interface.name' ${FILE_RESULT})                               
interfacemacaddr=$(jq -r '.interface.macAddr' ${FILE_RESULT})                         
interfaceisvpn=$(jq -r '.interface.isVpn' ${FILE_RESULT})                             
interfaceexternalip=$(jq -r '.interface.externalIp' ${FILE_RESULT})                   
servername=$(jq -r '.server.name' ${FILE_RESULT})                                     
servercountry=$(jq -r '.server.country' ${FILE_RESULT})                               
serverlocation=$(jq -r '.server.location' ${FILE_RESULT})                             
serverhost=$(jq -r '.server.host' ${FILE_RESULT})                                     
serverport=$(jq -r '.server.port' ${FILE_RESULT})                                     
serverip=$(jq -r '.server.ip' ${FILE_RESULT})                                         
resultid=$(jq -r '.result.id' ${FILE_RESULT})                                         
resulturl=$(jq -r '.result.url' ${FILE_RESULT})                                       
                                                                               
#############################################
# Affichage des resultats.
#############################################
echo "${TIMESTAMP} Speedtest results"                                          
echo "${TIMESTAMP} timestamp           = ${timestamp}"                                   
echo "${TIMESTAMP} jitter              = ${jitter} ms"                                  
echo "${TIMESTAMP} ping                = ${ping} ms"                                          
echo "${TIMESTAMP} download            = ${download} Mbps"                                
echo "${TIMESTAMP} upload              = ${upload} Mbps"                                    
echo "${TIMESTAMP} isp                 = ${isp}"                                               
echo "${TIMESTAMP} interfaceinternalip = ${interfaceinternalip}"           
echo "${TIMESTAMP} interfacename       = ${interfacename}"
echo "${TIMESTAMP} interfacemacaddr    = ${interfacemacaddr}"                     
echo "${TIMESTAMP} interfaceisvpn      = ${interfaceisvpn}"                         
echo "${TIMESTAMP} interfaceexternalip = ${interfaceexternalip}"           
echo "${TIMESTAMP} servername          = ${servername}"                                 
echo "${TIMESTAMP} serverlocation      = ${serverlocation}"                         
echo "${TIMESTAMP} servercountry       = ${servercountry}"                           
echo "${TIMESTAMP} serverhost          = ${serverhost}"                                 
echo "${TIMESTAMP} serverport          = ${serverport}"                             
echo "${TIMESTAMP} serverip            = ${serverip}"
echo "${TIMESTAMP} resultid            = ${resultid}"
echo "${TIMESTAMP} resulturl           = ${resulturl}"
echo "${TIMESTAMP} sending results to ${MQTT_HOST} as clientID ${MQTT_ID} with options ${MQTT_OPTIONS} using user ${MQTT_USER}"

#############################################                    
# Envoi des valeurs vers MQTT.                         
#############################################                                                                                      
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/timestamp -m "${timestamp}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/jitter -m "${jitter}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/ping -m "${ping}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/download -m "${download}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/upload -m "${upload}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/isp -m "${isp}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/interface/internalip -m "${interfaceinternalip}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/interface/name -m "${interfacename}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/interface/macaddr -m "${interfacemacaddr}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/interface/isvpn -m "${interfaceisvpn}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/interface/externalip -m "${interfaceexternalip}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/server/name -m "${servername}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/server/location -m "${serverlocation}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/server/country -m "${servercountry}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/server/host -m "${serverhost}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/server/port -m "${serverport}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/server/ip -m "${serverip}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/result/id -m "${resultid}"
/usr/bin/mosquitto_pub -h ${MQTT_HOST} -i ${MQTT_ID} ${MQTT_OPTIONS} -u ${MQTT_USER} -P ${MQTT_PASS} -t ${MQTT_TOPIC}/result/url -m "${resulturl}"
