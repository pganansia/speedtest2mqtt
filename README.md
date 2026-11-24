# speedtest2mqtt

Alpine-based docker to push Ookla Speedtest results to a MQTT Server.

## Environment Variables

    CRON (Default '17 */3 * * *' -> run speedtest every 3 hours, at minute 17)
    RANDOM_DELAY (Default '60' -> random wait of 0 to 60 seconds before each test)
    SPEEDTEST_SERVER_ID (Default '' -> server chosen automatically by Ookla)
    FILE_RESULT (Default '/config/ookla.json')
    MQTT_HOST (Default 'localhost')
    MQTT_PORT (Default '1883')
    MQTT_ID (Default 'speedtest2mqtt')
    MQTT_TOPIC (Default 'speedtest')
    MQTT_OPTIONS (Default '-r')
    MQTT_USER (Default '' -> no authentication)
    MQTT_PASS (Default '')

### Test frequency

Ookla limits the number of tests per IP address. Running a test too often
(for instance every 5 minutes, i.e. 288 tests a day) leads to the error
`Limit reached: Too many requests received`. A test every 1 to 6 hours is
a reasonable choice. Avoid round minutes (`0`, `30`) and keep `RANDOM_DELAY`
so that tests are not run at the same time as many other users.

Each test also downloads and uploads a large amount of data (several hundred
MB on a fiber connection).

## MQTT topics

All topics are published under `MQTT_TOPIC` (default `speedtest`):

    timestamp, jitter, ping, download, upload, isp
    interface/internalip, interface/name, interface/macaddr, interface/isvpn, interface/externalip
    server/name, server/location, server/country, server/host, server/port, server/ip
    result/id, result/url
    status      'ok' or 'error'
    error       error message of the last test ('' when the test succeeded)
    last_run    date of the last successful test

When a test fails (for instance because of the Ookla limit), only `status`
and `error` are updated: the previous results are kept.

## Scheduling

Tests are scheduled with the BusyBox `crond` included in Alpine: the image
contains no Python runtime. The schedule uses the time zone set by `TZ`
(default `Europe/Paris`).

## Upgrading from version 1.3 or earlier

The script and the schedule are now always taken from the image. The files
`speedtest2mqtt.sh`, `crontab.yml` and `container.env` previously copied into
`/config` are no longer used and can be deleted (`container.env` contained
your MQTT password in clear text).

## Examples

#### docker-compose.yml

```
services:
  speedtest2mqtt:
    image: pganansia/speedtest2mqtt:latest
    container_name: speedtest2mqtt
    network_mode: host
    environment:
      - CRON=17 */3 * * *
      - FILE_RESULT=/config/ookla.json
      - MQTT_HOST=${MQTT_HOST}
      - MQTT_USER=${MQTT_USER}
      - MQTT_PASS=${MQTT_PASS}
      - MQTT_ID=speedtest2mqtt
      - MQTT_TOPIC=speedtest
      - MQTT_OPTIONS=-r
    volumes:
      - <path config directory on host>:/config
    restart: unless-stopped
```

with a `.env` file next to `docker-compose.yml`:

```
MQTT_HOST=192.168.100.100
MQTT_USER=user_mqtt
MQTT_PASS=password_mqtt
```

#### docker

```
docker run -d --volume <path config directory on host>:/config --env-file ./env.list pganansia/speedtest2mqtt:latest
```

with env.list

```
CRON=17 */3 * * *
MQTT_HOST=192.168.100.100
MQTT_USER=user_mqtt
MQTT_PASS=password_mqtt
```

## Releasing a new version

1. Merge the changes into `main` (the `CI` workflow must succeed).
2. Create a GitHub release with a tag in the `vX.Y.Z` format (for instance `v1.4.0`).
3. The `Release` workflow builds the image for `linux/amd64`, `linux/arm64` and
   `linux/arm/v7`, pushes it to Docker Hub and GitHub Container Registry with
   the tags `X.Y.Z`, `X.Y` and `latest`, and signs it.

## Note

This docker image uses [ookla speedtest cli](https://www.speedtest.net/fr/apps/cli) and automatically 
accepts Ookla License and GDPR terms.
 
## Ookla speedtest License

You may only use this Speedtest software and information generated from it for personal, non-commercial use, through a command line interface on a personal computer. Your use of this software is subject to the End User License Agreement, Terms of Use and Privacy Policy at these URLs:

https://www.speedtest.net/about/eula
https://www.speedtest.net/about/terms
https://www.speedtest.net/about/privacy

## Ookla speedtest GDPR

Ookla collects certain data through Speedtest that may be considered
personally identifiable, such as your IP address, unique device
identifiers or location. Ookla believes it has a legitimate interest
to share this data with internet providers, hardware manufacturers and
industry regulators to help them understand and create a better and
faster internet. For further information including how the data may be
shared, where the data may be transferred and Ookla's contact details,
please see our Privacy Policy at:

http://www.speedtest.net/privacy
