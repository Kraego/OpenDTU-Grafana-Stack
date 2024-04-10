#!/bin/bash

INFLUX_START_DELAY=3

# check for mac os and create sed alias
if [[ "$OSTYPE" == "darwin"* ]]; then
    if ! command -v gsed &> /dev/null 
    then
        echo "##### gsed missing for mac os, install it, f.e. with brew 'brew install gsed' ... exiting"
        exit
    else
        shopt -s expand_aliases
        alias sed=gsed
    fi
fi

# Load env file
ENV_FILE=.env
echo "##### Load settings from $ENV_FILE"
set -o allexport
source "$ENV_FILE"
set +o allexport

echo "##### Creating folders"
mkdir -p ./mosquitto/log ./mosquitto/data ./mosquitto/certs ./influxdb/config ./influxdb/data ./grafana/var/lib/grafana/plugins

echo "##### Pulling images"
docker-compose pull

echo "##### Configuring mosquitto user - $MQTT_USER"
#remove carriage return
mqttuser=$(echo "$MQTT_USER" | tr -d '\r')
mqttpw=$(echo "$MQTT_PW" | tr -d '\r')

docker-compose up mosquitto -d
docker-compose exec mosquitto mosquitto_passwd -b /mosquitto/conf/password.txt $mqttuser $mqttpw
docker-compose down

echo "##### Creating influx buckets and downsample tasks"
docker-compose up influxdb -d
sleep $INFLUX_START_DELAY
docker-compose exec influxdb /bin/sh -c '/setup/setupInflux.sh' 
docker-compose down

echo "##### influx token (wait $INFLUX_START_DELAY seconds for influx to start)"
docker-compose up influxdb -d
sleep $INFLUX_START_DELAY
auth_list="$(docker-compose exec influxdb influx auth list -u $INFLUX_USER_NAME)"
docker-compose down
auth_token=$(echo "$auth_list" | awk 'NR==2 {print $4}')
echo "##### The user token is: '$auth_token'"

echo "##### Setting token in environment"
sed -i '/^INFLUX_TOKEN=/s/=.*/='"$auth_token"'/' .env

echo "##### Updating grafana datasource with new values from env"
sed -i 's,\[TOKEN\], '$auth_token', g' ./grafana/provisioning/datasources/default.yaml
sed -i 's,\[ORGANIZATION\],'$GRAFANA_ORG_NAME', g' ./grafana/provisioning/datasources/default.yaml

echo $"##### Done, You now can start the stack with 'docker-compose up -d'"
