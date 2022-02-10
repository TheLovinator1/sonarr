FROM archlinux
# TODO: Check https://services.sonarr.tv/v1/releases instead of hardcoded version

# https://github.com/opencontainers/image-spec/blob/main/annotations.md#pre-defined-annotation-keys
LABEL org.opencontainers.image.authors="Joakim Hellsén <tlovinator@gmail.com>" \ 
org.opencontainers.image.url="https://github.com/TheLovinator1/docker-arch-sonarr" \
org.opencontainers.image.documentation="https://github.com/TheLovinator1/docker-arch-sonarr" \
org.opencontainers.image.source="https://github.com/TheLovinator1/docker-arch-sonarr" \
org.opencontainers.image.vendor="Joakim Hellsén" \
org.opencontainers.image.license="GPL-3.0+" \
org.opencontainers.image.title="Sonarr" \
org.opencontainers.image.description="Sonarr will monitor RSS feeds for new episodes of your favorite shows and download them" \
org.opencontainers.image.base.name="docker.io/library/archlinux"

# Sonarr version
ARG pkgver="3.0.6.1451"

# Add mirrors for Sweden. You can add your own mirrors to the mirrorlist file. Should probably use reflector.
ADD mirrorlist /etc/pacman.d/mirrorlist

# NOTE: For Security Reasons, archlinux image strips the pacman lsign key.
# This is because the same key would be spread to all containers of the same
# image, allowing for malicious actors to inject packages (via, for example,
# a man-in-the-middle).
RUN gpg --refresh-keys && pacman-key --init && pacman-key --populate archlinux

# Set locale. Needed for some programs.
# https://wiki.archlinux.org/title/locale
RUN echo "en_US.UTF-8 UTF-8" >"/etc/locale.gen" && locale-gen && echo "LANG=en_US.UTF-8" >"/etc/locale.conf"

# Create a new user with id 1000 and name "sonarr".
# Also create folder that we will use later.
# https://linux.die.net/man/8/useradd
# https://linux.die.net/man/8/groupadd
RUN groupadd --gid 1000 --system sonarr && \
useradd --system --uid 1000 --gid 1000 sonarr && \
install -d -o sonarr -g sonarr -m 775 /var/lib/sonarr /usr/lib/sonarr/bin /tmp/sonarr /media

# Update the system and install depends
RUN pacman -Syu --noconfirm && pacman -S mono libmediainfo sqlite --noconfirm

# Add custom Package Version under System -> Status
ADD package_info /tmp/sonarr

# Download and extract everything to /tmp/sonarr, it will be removed after installation
WORKDIR /tmp/sonarr

# Download and extract the package
# TODO: We should check checksums here
ADD "https://download.sonarr.tv/v3/develop/${pkgver}/Sonarr.develop.${pkgver}.linux.tar.gz" "/tmp/sonarr/Sonarr.develop.${pkgver}.linux.tar.gz"
RUN tar -xf "Sonarr.develop.${pkgver}.linux.tar.gz" -C /tmp/sonarr && \
rm "Sonarr.develop.${pkgver}.linux.tar.gz" && \
rm -rf "Sonarr/Sonarr.Update" && \
cp -dpr "Sonarr/." "/usr/lib/sonarr/bin" && \
install -D -m 644 "package_info" "/usr/lib/sonarr" && \
echo "PackageVersion=${pkgver}" >>"/usr/lib/sonarr/package_info" && \
rm -rf "/tmp/sonarr" && \
chown -R sonarr:sonarr /var/lib/sonarr /usr/lib/sonarr /media && \
rm -rf /var/cache/*

# Where Sonarr will store its data
WORKDIR /var/lib/sonarr

# Web UI
EXPOSE 8989/tcp

# Read README.md for more information on how to set up your volumes
VOLUME ["/media", "/var/lib/sonarr"]

# Don't run as root
USER sonarr

# We run mono with the --debug flag to get a stack trace on crash and more diagnostic information at a negligible performance cost.
CMD [ "mono", "--debug", "/usr/lib/sonarr/bin/Sonarr.exe", "-nobrowser", "-data=/var/lib/sonarr"]
