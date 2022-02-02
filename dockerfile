FROM archlinux
# TODO: Check https://services.sonarr.tv/v1/releases instead of hardcoded version

ARG pkgver="3.0.6.1451"
ARG source="https://download.sonarr.tv/v3/develop/${pkgver}/Sonarr.develop.${pkgver}.linux.tar.gz"

# Add mirrors for Sweden. You can add your own mirrors to the mirrorlist file. Should probably use reflector.
ADD mirrorlist /etc/pacman.d/mirrorlist

# NOTE: For Security Reasons, archlinux image strips the pacman lsign key.
# This is because the same key would be spread to all containers of the same
# image, allowing for malicious actors to inject packages (via, for example,
# a man-in-the-middle).
RUN gpg --refresh-keys && pacman-key --init && pacman-key --populate archlinux

# Set locale. Needed for some programs.
# https://wiki.archlinux.org/title/locale
RUN echo "en_US.UTF-8 UTF-8" > "/etc/locale.gen" && locale-gen && echo "LANG=en_US.UTF-8" > "/etc/locale.conf"

# Create a new user with id 1000 and name "sonarr".
# https://linux.die.net/man/8/useradd
# https://linux.die.net/man/8/groupadd
RUN groupadd --gid 1000 --system sonarr && \
    useradd --system --uid 1000 --gid 1000 sonarr && \
    install -d -o sonarr -g sonarr -m 775 /var/lib/sonarr /usr/lib/sonarr/bin /tmp/sonarr /media

# Update the system and install depends
RUN pacman -Syu --noconfirm && pacman -S mono libmediainfo sqlite wget --noconfirm

ADD package_info /tmp/sonarr

WORKDIR /tmp/sonarr

RUN wget "${source}" -O "Sonarr.develop.${pkgver}.linux.tar.gz"
RUN tar -xf "Sonarr.develop.${pkgver}.linux.tar.gz" -C /tmp/sonarr && \
    rm "Sonarr.develop.${pkgver}.linux.tar.gz" && \
    rm -rf "Sonarr/Sonarr.Update" && \
    cp -dpr "Sonarr/." "/usr/lib/sonarr/bin" && \
    install -D -m 644 "package_info" "/usr/lib/sonarr" && \
    echo "PackageVersion=${pkgver}" >> "/usr/lib/sonarr/package_info" && \
    rm -rf "/tmp/sonarr" && \
    chown -R sonarr:sonarr /var/lib/sonarr /usr/lib/sonarr /media && \
    pacman -Rs --noconfirm wget && \
    rm -rf /var/cache/*

WORKDIR /var/lib/sonarr

EXPOSE 8989
VOLUME ["/media", "/var/lib/sonarr"]

USER sonarr

CMD [ "mono", "--debug", "/usr/lib/sonarr/bin/Sonarr.exe", "-nobrowser", "-data=/var/lib/sonarr"]