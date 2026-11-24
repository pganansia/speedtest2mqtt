# syntax=docker/dockerfile:1
FROM alpine:3.24.1

# Fournis automatiquement par Buildx pour chaque plateforme
ARG TARGETARCH
ARG TARGETVARIANT
# Version du client Ookla Speedtest
ARG OOKLA_VERSION=1.2.0

ENV TZ=Europe/Paris

# Les labels de version et de date sont ajoutés par docker/metadata-action
LABEL org.opencontainers.image.authors="Pierre Ganansia" \
      org.opencontainers.image.title="Speedtest2mqtt" \
      org.opencontainers.image.description="Speedtest trough MQTT for Home Assistant. Thanks to moafrancky" \
      org.opencontainers.image.url="https://github.com/pganansia/speedtest2mqtt" \
      org.opencontainers.image.source="https://github.com/pganansia/speedtest2mqtt" \
      org.opencontainers.image.licenses="GPL-3.0"

# hadolint ignore=DL3018
RUN apk add --no-cache bash jq mosquitto-clients tzdata python3

# Environnement Python de yacron : les outils de compilation ne servent
# qu'à l'installation et sont retirés dans la même couche
COPY requirements.txt /tmp/requirements.txt
# hadolint ignore=DL3018,DL3013
RUN apk add --no-cache --virtual .build-deps gcc musl-dev python3-dev \
    && python3 -m venv /speedtest2mqtt \
    && /speedtest2mqtt/bin/pip install --no-cache-dir --upgrade pip \
    && /speedtest2mqtt/bin/pip install --no-cache-dir -r /tmp/requirements.txt \
    && apk del .build-deps \
    && rm /tmp/requirements.txt

# Client Ookla Speedtest selon l'architecture
# (linux/arm/v6 -> armel, linux/arm/v7 -> armhf)
RUN case "${TARGETARCH}${TARGETVARIANT:+/${TARGETVARIANT}}" in \
        amd64)  OOKLA_ARCH=x86_64 ;; \
        386)    OOKLA_ARCH=i386 ;; \
        arm64)  OOKLA_ARCH=aarch64 ;; \
        arm/v7) OOKLA_ARCH=armhf ;; \
        arm/v6) OOKLA_ARCH=armel ;; \
        *) echo "Unsupported architecture: ${TARGETARCH}${TARGETVARIANT:+/${TARGETVARIANT}}" && exit 1 ;; \
    esac \
    && wget -q "https://install.speedtest.net/app/cli/ookla-speedtest-${OOKLA_VERSION}-linux-${OOKLA_ARCH}.tgz" -O /tmp/speedtest.tgz \
    && tar xzf /tmp/speedtest.tgz -C /usr/local/bin speedtest \
    && rm /tmp/speedtest.tgz \
    && speedtest --version

COPY --chmod=755 speedtest2mqtt.sh /app/config/speedtest2mqtt.sh
COPY crontab.yml /app/config/crontab.yml
COPY --chmod=755 entrypoint.sh /entrypoint.sh

VOLUME ["/config"]

# Le conteneur est sain tant que le planificateur tourne
HEALTHCHECK --interval=5m --timeout=10s CMD pgrep -f yacron > /dev/null || exit 1

ENTRYPOINT ["/entrypoint.sh"]
