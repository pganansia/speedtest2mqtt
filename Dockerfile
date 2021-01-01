FROM alpine:latest
ARG TARGETARCH

RUN apk --no-cache add bash mosquitto-clients jq wget dcron libcap && \
    echo "Target Arch $TARGETARCH"
    if test "$TARGETARCH}" = 'amd64'; then wget https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-x86_64-linux.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    if test "$TARGETARCH}" = 'arm/v7'; then wget https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-arm-linux.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    if test "$TARGETARCH}" = 'arm64'; then wget https://bintray.com/ookla/download/download_file?file_path=ookla-speedtest-1.0.0-arm-linux.tgz -O /var/tmp/speedtest.tar.gz; fi && \
    tar xf /var/tmp/speedtest.tar.gz -C /var/tmp && \
    mv /var/tmp/speedtest /usr/local/bin && \
    rm /var/tmp/speedtest.tar.gz

RUN addgroup -S foo && adduser -S foo -G foo && \
    chown foo:foo /usr/sbin/crond && \
    setcap cap_setgid=ep /usr/sbin/crond

ADD ./entrypoint.sh /opt/entrypoint.sh
ADD ./speedtest2mqtt.sh /opt/speedtest2mqtt.sh
RUN chmod +x /opt/speedtest2mqtt.sh /opt/entrypoint.sh

USER foo

ENTRYPOINT /opt/entrypoint.sh

