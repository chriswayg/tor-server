#
# Dockerfile for Tor Relay Server
#
# This will build & install a Tor Debian package using 
# the official instructions for installing Tor on Debian Jessie from source
# as detailed here https://www.torproject.org/docs/debian.html.en
#
# Usage:
#   docker run -d --restart=always -p 9001:9001 chriswayg/tor-server

FROM debian:jessie
MAINTAINER Christian chriswayg@gmail.com

# If no Nickname is set, a random string will be added to 'Tor4'
ENV TOR_NICKNAME=Tor4 \
    TERM=xterm 

# Add the official torproject.org Debian Tor repository
# - this will always build/install the latest stable version
COPY ./config/tor-apt-sources.list /etc/apt/sources.list.d/

# Build & Install:
# - add the gpg key used to sign the packages
# - install build dependencies (and nano)
# - add a 'builder' user for compiling the package as a non-root user
# - build Tor in ~/debian-packages and install the new Tor package
# - backup torrc & cleanup all dependencies and caches
# - adds only 13 MB to the Debian base image (without obfsproxy, which adds another 60 MB)
RUN gpg --keyserver keys.gnupg.net --recv 886DDD89 && \
    gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add - && \
    apt-get update && \
    build_deps="build-essential fakeroot devscripts quilt libssl-dev zlib1g-dev libevent-dev \
        asciidoc docbook-xml docbook-xsl xmlto dh-apparmor libseccomp-dev dh-systemd \
        libsystemd-dev pkg-config dh-autoreconf hardening-includes" && \
    DEBIAN_FRONTEND=noninteractive apt-get -y --no-install-recommends install $build_deps \
        obfsproxy \
        tor-geoipdb \
        init-system-helpers \
        pwgen \
        nano && \ 
    adduser --disabled-password --gecos "" builder && \
    su builder -c 'mkdir -v ~/debian-packages; cd ~/debian-packages && \
    apt-get -y source tor && \
    cd tor-* && \
    debuild -rfakeroot -uc -us' && \
    dpkg -i /home/builder/debian-packages/tor_*.deb && \
    mv -v /etc/tor/torrc /etc/tor/torrc.default && \
    deluser --remove-home builder && \
    apt-get -y purge --auto-remove $build_deps && \
    apt-get clean && rm -r /var/lib/apt/lists/*

# Copy Tor configuration file
COPY ./config/torrc /etc/tor/torrc

# Copy docker-entrypoint
COPY ./scripts/ /usr/local/bin/

# Persist data
VOLUME /etc/tor /var/lib/tor

# ORPort, DirPort, ObfsproxyPort
EXPOSE 9001 9030 54444

ENTRYPOINT ["docker-entrypoint"]

CMD ["tor", "-f", "/etc/tor/torrc"]