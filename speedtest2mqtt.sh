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
file=/app/config/ookla.json
#file=/app/config/${TIMESTAMP}_ookla.json                                                                                      

#############################################
# Lancement du traitement.
#############################################
echo "${TIMESTAMP} Starting speedtest"
echo "${TIMESTAMP} Result file: ${file}"

#############################################
# Lancement de speedtest.
#############################################                                                                                      
speedtest --accept-license --accept-gdpr -f json-pretty > ${file}

#############################################
# Test d'un resultat en erreur.
#############################################
nberror=$(jq -r '.error' ${file} | wc -w)
echo "${TIMESTAMP} Erreur de traitement nb mots: ${nberror}"
if [ ${nberror} -gt 1 ];
then
    echo "${TIMESTAMP} error in results";
    exit;
fi

#############################################
# Recuperation des resultats.
#############################################
timestamp=$(jq -r '.timestamp' ${file})
jitter=$(jq -r '.ping.jitter' ${file})
ping=$(jq -r '.ping.latency' ${file})
download=$(printf %.2f\\n "$(($(jq -r '.download.bandwidth' ${file}) * 8))e-6")
upload=$(printf %.2f\\n "$(($(jq -r '.upload.bandwidth' ${file}) * 8))e-6")
isp=$(jq -r '.isp' ${file})                                                    
interfaceinternalip=$(jq -r '.interface.internalIp' ${file})                   
interfacename=$(jq -r '.interface.name' ${file})                               
interfacemacaddr=$(jq -r '.interface.macAddr' ${file})                         
interfaceisvpn=$(jq -r '.interface.isVpn' ${file})                             
interfaceexternalip=$(jq -r '.interface.externalIp' ${file})                   
servername=$(jq -r '.server.name' ${file})                                     
servercountry=$(jq -r '.server.country' ${file})                               
serverlocation=$(jq -r '.server.location' ${file})                             
serverhost=$(jq -r '.server.host' ${file})                                     
serverport=$(jq -r '.server.port' ${file})                                     
serverip=$(jq -r '.server.ip' ${file})                                         
resultid=$(jq -r '.result.id' ${file})                                         
resulturl=$(jq -r '.result.url' ${file})                                       
                                                                               
#############################################
# Affichage des resultats.
#############################################
echo "${TIMESTAMP} Speedtest results"                                          
echo "${TIMESTAMP} timestamp = ${timestamp}"                                   
echo "${TIMESTAMP} jitter = ${jitter} ms"                                  
echo "${TIMESTAMP} ping = ${ping} ms"                                          
echo "${TIMESTAMP} download = ${download} Mbps"                                
echo "${TIMESTAMP} upload = ${upload} Mbps"                                    
echo "${TIMESTAMP} isp = ${isp}"                                               
echo "${TIMESTAMP} interfaceinternalip = ${interfaceinternalip}"           
echo "${TIMESTAMP} interfacename = ${interfacename}"
echo "${TIMESTAMP} interfacemacaddr = ${interfacemacaddr}"                     
echo "${TIMESTAMP} interfaceisvpn = ${interfaceisvpn}"                         
echo "${TIMESTAMP} interfaceexternalip = ${interfaceexternalip}"           
echo "${TIMESTAMP} servername = ${servername}"                                 
echo "${TIMESTAMP} serverlocation = ${serverlocation}"                         
echo "${TIMESTAMP} servercountry = ${servercountry}"                           
echo "${TIMESTAMP} serverhost = ${serverhost}"                                 
echo "${TIMESTAMP} serverport = ${serverport}"                             
echo "${TIMESTAMP} serverip = ${serverip}"
echo "${TIMESTAMP} resultid = ${resultid}"
echo "${TIMESTAMP} resulturl = ${resulturl}"
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
