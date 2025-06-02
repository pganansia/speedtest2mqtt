FROM alpine:3.22.0
ARG TARGETARCH
ARG DATE
ARG VERSION
LABEL org.opencontainers.image.authors="Pierre Ganansia"
LABEL org.opencontainers.image.title="Speedtest2mqtt"
LABEL org.opencontainers.image.description="Speedtest trough MQTT for Home Assistant. Thanks to maofrancky"
LABEL org.opencontainers.image.url="https://github.com/pganansia/speedtest2mqtt"
LABEL org.opencontainers.image.source="https://github.com/pganansia/speedtest2mqtt"
LABEL org.opencontainers.image.licenses="GPL-3.0"
LABEL org.opencontainers.image.created=${DATE}
LABEL org.opencontainers.image.version=${VERSION}

RUN mkdir -p /app
RUN mkdir -p /app/config
COPY --chmod=755 speedtest2mqtt.sh /app/config
COPY crontab.yml /app/config
COPY --chmod=755 entrypoint.sh /

RUN apk add --no-cache tzdata
ENV TZ=Europe/Paris

RUN apk --no-cache add bash mosquitto-clients jq python3
RUN apk --no-cache add wget --virtual .build-deps && \
    echo "Target Arch $TARGETARCH" && \
    if test "$TARGETARCH" = '386'; then wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-i386.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    if test "$TARGETARCH" = 'amd64'; then wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    if test "$TARGETARCH" = 'arm'; then wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-armhf.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    if test "$TARGETARCH" = 'arm64'; then wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    if test "$TARGETARCH" = 'arm/v6'; then wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-armel.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    tar xf /var/tmp/speedtest.tar.gz -C /var/tmp && \
    mv /var/tmp/speedtest /usr/local/bin && \
    rm /var/tmp/speedtest.tar.gz && \
    apk del --no-cache .build-deps
RUN apk --no-cache add gcc musl-dev python3-dev --virtual .build-deps && \
    python3 -m venv yacronenv && \
    . yacronenv/bin/activate && \
    pip install yacron && \
    apk del --no-cache .build-deps

VOLUME ["/config"]

ENTRYPOINT ["/entrypoint.sh"]
