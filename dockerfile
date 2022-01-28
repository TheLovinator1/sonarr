FROM alpine:edge
# TODO: Check https://services.sonarr.tv/v1/releases instead of hardcoded version

ARG pkgver="3.0.6.1451"
ARG source="https://download.sonarr.tv/v3/develop/${pkgver}/Sonarr.develop.${pkgver}.linux.tar.gz"

RUN addgroup -g 1000 sonarr && \
    adduser -u 1000 -Hh /var/lib/sonarr -G sonarr -s /sbin/nologin -D sonarr && \
    install -d -o sonarr -g sonarr -m 775 /var/lib/sonarr /usr/lib/sonarr/bin /tmp/sonarr /downloads

RUN apk add -U --upgrade --no-cache libmediainfo sqlite-libs ca-certificates 
RUN apk add mono --no-cache --repository=https://ftp.acc.umu.se/mirror/alpinelinux.org/edge/testing/

ADD package_info /tmp/sonarr

WORKDIR /tmp/sonarr

RUN wget "${source}" && \ 
    tar -xf "Sonarr.develop.${pkgver}.linux.tar.gz" -C /tmp/sonarr && \
    rm "Sonarr.develop.${pkgver}.linux.tar.gz" && \
    rm -rf "Sonarr/Sonarr.Update" && \
    install -d -m 755 "/usr/lib/sonarr/bin" && \
    cp -dpr "Sonarr/." "/usr/lib/sonarr/bin" && \
    install -D -m 644 "package_info" "/usr/lib/sonarr" && \
    echo "PackageVersion=${pkgver}" >> "/usr/lib/sonarr/package_info" && \
    rm -rf "/tmp/sonarr" && \
    cert-sync /etc/ssl/certs/ca-certificates.crt && \
    chown -R sonarr:sonarr /var/lib/sonarr /usr/lib/sonarr /downloads

WORKDIR /var/lib/sonarr

EXPOSE 8989
VOLUME ["/downloads", "/var/lib/sonarr"]

CMD [ "mono", "--debug", "/usr/lib/sonarr/bin/Sonarr.exe", "-nobrowser", "-data=/var/lib/sonarr"]