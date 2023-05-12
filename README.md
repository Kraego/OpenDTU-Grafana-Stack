# Mosquitto-Telegraf-Influx-Grafana Stack

This is a docker stack created to visualize the topics of a opendDTU (https://github.com/tbnobody/OpenDTU). Mqtt communication with basic auth an let's encrypt certificates. Basically it is the dockerized version of https://github.com/Kraego/OpenDTU-Grafana-Howto.

It consists of:
  * `mosquitto` (mqtt broker)
  * `telegraf` (mqtt -> influxDB2)
  * `influxDB2` (store the timeframes in buckets)
  * `grafana` (monitoring)

## Prequesites

* The following ports must be open on host (so if you have a firewall unblock these ports)
  * `3000` for grafana (webinterface)
  * `8883` for mqtt broker (to receive publishes from openDTU)
* if you want **skip the tls cert stuff** comment line 6-8 in the `mosquitto.conf`
* **Install `Certbot` on your Host**
  * update `[YOUR DOMAIN]` and `[DIR MOUNT OF MOSQUITTO CONTAINER ON HOST]` (./mosquitto/certs) in `mosquitto-copy-certs.sh`
  * copy the file `mosquitto-copy-certs.sh` to your certbot renewal hooks dir (on Linux it is: /etc/letsencrypt/renewal-hooks/deploy) and make it executable (`chmod +x mosquitto-copy-certs.sh`)

## How to use it

1. Clone Repo
    ```
    git clone https://github.com/Kraego/OpenDTU-Mosquitto-Telegraf-Influx-Grafana-Stack.git
    ```
1. Go to directory where you have cloned the repo
2. Create a `.env` file from the template
   * rename `.env_template` to `.env`
   * configure the variables with your values 
3. Setup the **mosquitto user** with same values as in your `.env` file (replace `mqtt_user` and `mqtt_pw` with your values used in `.env`)
   ```
   docker-compose exec mosquitto mosquitto_passwd -b /mosquitto/conf/password.txt mqtt_user mqtt_pw
   ```
   * Configure your open DTU to this broker
4. Create influx buckets and downsample tasks
   ```
   docker-compose up influxdb -d
   docker-compose exec influxdb /bin/sh -c '/setup/setupInflux.sh' 
   docker-compose down
   ```
5. Start up the whole stack
   ```
   docker-compose up -d
   ```
6. Setup grafana over: http://localhost:3000
   * add Datasource
     * url: http://influxdb:8086
     * organization the same as in your `.env` File
     * Basic Auth: User and password again from your `.env` File
     * Get the token: `docker-compose exec influxdb influx auth list`
       * copy the token to the textbox
7. Add or create Dashboards

**YOUR DONE**

## Improvements

Things I didn't did but would be nice:

* Run influx setup automatically when done with init
* Run certbot internal as service (how to pass the let's encrypt challenge?)
* Nicer setup of mqtt user
* ....
  

