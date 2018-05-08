#
# Dockerfile for Tor Relay Server with obfs4proxy
#
# This will install the Tor Debian package and obfs4proxy using
# the official instructions for installing Tor on Debian
# as detailed here https://www.torproject.org/docs/debian.html.en
# and https://trac.torproject.org/projects/tor/wiki/doc/PluggableTransports/obfs4proxy
#
# Usage:
#   docker run -d --restart=always -p 9001:9001 chriswayg/tor-server

FROM debian:stretch
MAINTAINER Christian chriswayg@gmail.com

# If no Nickname is set, a random string will be added to 'Tor4'
ENV TOR_NICKNAME=Tor4 \
    TERM=xterm

# Install prerequisites
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
      apt-transport-https \
      ca-certificates \
      dirmngr \
      apt-utils \
      gnupg && \
    apt-get clean && rm -rv /var/lib/apt/lists/*

# Add the official torproject.org Debian Tor repository
# - this will always build/install the latest stable version
COPY ./config/tor-apt-sources.list /etc/apt/sources.list.d/

# Add GPG key used to sign the packages; try various keyservers
RUN GPG_KEY="A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89" && \
     ( gpg --keyserver ha.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
    || gpg --keyserver ipv4.pool.sks-keyservers.net --recv-keys "$GPG_KEY" \
    || gpg --keyserver pgp.mit.edu --recv-keys "$GPG_KEY" \
    || gpg --keyserver keys.gnupg.net --recv-keys "$GPG_KEY" ) && \
    gpg --export "$GPG_KEY" | apt-key add -

# Install:
# - install tor and obfs4proxy
# - backup torrc
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install --no-install-recommends \
      tor \
      deb.torproject.org-keyring \
      obfs4proxy && \
    mv -v /etc/tor/torrc /etc/tor/torrc.default && \
    apt-get clean && rm -rv /var/lib/apt/lists/*

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
