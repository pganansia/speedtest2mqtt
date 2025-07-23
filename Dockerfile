FROM alpine:3.22.1

ARG TARGETARCH
ARG DATE
ARG VERSION
ENV TZ=Europe/Paris
ENV TZ=Europe/Paris
LABEL org.opencontainers.image.authors="Pierre Ganansia"
LABEL org.opencontainers.image.title="Speedtest2mqtt"
LABEL org.opencontainers.image.description="Speedtest trough MQTT for Home Assistant. Thanks to moafrancky"
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

# Installation de bash, jq, mosquitto-clients, tzdata et wget
RUN apk --no-cache add bash jq mosquitto-clients tzdata wget 
# Installation de python3 
RUN apk --no-cache add python3>3.12.10
# Installation des outils pour yacron 
RUN apk --no-cache add gcc musl-dev python3-dev

# Installation d'un environnement virtuel 
RUN python3 -m venv speedtest2mqtt && \
    . speedtest2mqtt/bin/activate
COPY requirements.txt .
RUN speedtest2mqtt/bin/pip install --upgrade pip
RUN speedtest2mqtt/bin/pip install --no-cache-dir -r requirements.txt
RUN speedtest2mqtt/bin/pip install yacron

RUN echo "Target Arch $TARGETARCH" && \
RUN mkdir -p /app
RUN mkdir -p /app/config
COPY --chmod=755 speedtest2mqtt.sh /app/config
COPY crontab.yml /app/config
COPY --chmod=755 entrypoint.sh /

# Installation de bash, jq, mosquitto-clients, tzdata et wget
RUN apk --no-cache add bash jq mosquitto-clients tzdata wget 
# Installation de python3 
RUN apk --no-cache add python3
# Installation des outils pour yacron 
RUN apk --no-cache add gcc musl-dev python3-dev

# Installation d'un environnement virtuel 
RUN python3 -m venv speedtest2mqtt && \
    . speedtest2mqtt/bin/activate
COPY requirements.txt .
RUN speedtest2mqtt/bin/pip install --upgrade pip
RUN speedtest2mqtt/bin/pip install --no-cache-dir -r requirements.txt
RUN speedtest2mqtt/bin/pip install yacron

RUN echo "Target Arch $TARGETARCH" && \
    if test "$TARGETARCH" = '386'; then wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-i386.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    if test "$TARGETARCH" = 'amd64'; then wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-x86_64.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    if test "$TARGETARCH" = 'arm'; then wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-armhf.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    if test "$TARGETARCH" = 'arm64'; then wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-aarch64.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    if test "$TARGETARCH" = 'arm/v6'; then wget https://install.speedtest.net/app/cli/ookla-speedtest-1.2.0-linux-armel.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    tar xf /var/tmp/speedtest.tar.gz -C /var/tmp && \
    mv /var/tmp/speedtest /usr/local/bin && \
    rm /var/tmp/speedtest.tar.gz

VOLUME ["/config"]

ENTRYPOINT ["/entrypoint.sh"]
