# c#!/bin/sh

SETUPDONE_FILE=/setup/DONE

if [ -f "$SETUPDONE_FILE" ]; then
    echo 'Setup of Influx db already done'
else
    # Setup influx db buckets
    influx bucket create -o $DOCKER_INFLUXDB_INIT_ORG -n telegraf/day --retention 1d --shard-group-duration 1h
    influx bucket create -o $DOCKER_INFLUXDB_INIT_ORG  -n telegraf/week --retention 7d --shard-group-duration 1d
    influx bucket create -o $DOCKER_INFLUXDB_INIT_ORG  -n telegraf/month --retention 31d --shard-group-duration 1d
    influx bucket create -o $DOCKER_INFLUXDB_INIT_ORG  -n telegraf/year --retention 366d --shard-group-duration 7d

    # add downsampling tasks
    influx task create -org $DOCKER_INFLUXDB_INIT_ORG -f /setup/tasks/telegraf_downsample_day
    influx task create -org $DOCKER_INFLUXDB_INIT_ORG -f /setup/tasks/telegraf_downsample_week
    influx task create -org $DOCKER_INFLUXDB_INIT_ORG -f /setup/tasks/telegraf_downsample_month
    influx task create -org $DOCKER_INFLUXDB_INIT_ORG -f /setup/tasks/telegraf_downsample_year

    touch $SETUPDONE_FILE
fi
