# Dockerfile for Tor Relay Server with obfs4proxy (Multi-Stage build)
FROM golang:buster AS go-build

# Build /go/bin/obfs4proxy & /go/bin/meek-server
RUN go get -v gitlab.com/yawning/obfs4.git/obfs4proxy \
 && go get -v git.torproject.org/pluggable-transports/meek.git/meek-server \
 && cp -rv /go/bin /usr/local/

FROM debian:buster-slim
MAINTAINER RJ dbarj@example.com

ARG GPGKEY=A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89
ARG APT_KEY_DONT_WARN_ON_DANGEROUS_USAGE="True"
ARG DEBIAN_FRONTEND=noninteractive
ARG found=""

# Set a default Nickname
ENV TOR_NICKNAME=Tor4
ENV TOR_USER=tord
ENV TERM=xterm

# Install prerequisites
RUN apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests -y \
        apt-transport-https \
        ca-certificates \
        dirmngr \
        apt-utils \
        gnupg \
        curl \
# Add torproject.org Debian repository for buster Tor version
 && curl https://deb.torproject.org/torproject.org/A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89.asc | gpg --import \
 && gpg --export A3C4F0F979CAA22CDBA8F512EE8CBC9E886DDD89 | apt-key add - \
 && echo "deb https://deb.torproject.org/torproject.org buster main"   >  /etc/apt/sources.list.d/tor-apt-sources.list \
 && echo "deb-src https://deb.torproject.org/torproject.org buster main" >> /etc/apt/sources.list.d/tor-apt-sources.list \
# Install tor with GeoIP and obfs4proxy & backup torrc
 && apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests -y \
        build-essential \
        fakeroot \
        devscripts \
        libcap-dev \
 && apt-get build-dep --no-install-recommends --no-install-suggests -y \
        tor \
        deb.torproject.org-keyring \
 && mkdir tor-install \
 && cd tor-install/ \
 && apt-get source tor \
 && cd tor-*/ \
 && debuild -rfakeroot -uc -us \
 && cd .. \
 && dpkg -i tor_*.deb tor-*.deb \
 && cd .. \
 && rm -rf tor-install/ \
 && tor --version \
 && apt-get install --no-install-recommends --no-install-suggests -y \
        pwgen \
        iputils-ping \
#        deb.torproject.org-keyring \
#        tor \
#        tor-geoipdb \
 && mkdir -pv /usr/local/etc/tor/ \
 && mv -v /etc/tor/torrc /usr/local/etc/tor/torrc.sample \
 && apt-get purge --auto-remove -y \
        apt-transport-https \
        dirmngr \
        apt-utils \
        gnupg \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
# Rename Debian unprivileged user to tord
 && usermod -l $TOR_USER debian-tor \
 && groupmod -n $TOR_USER debian-tor

# Copy obfs4proxy & meek-server
COPY --from=go-build /usr/local/bin/ /usr/local/bin/

# Copy Tor configuration file
COPY ./torrc /etc/tor/torrc

# Copy docker-entrypoint
COPY ./scripts/ /usr/local/bin/

# Persist data
VOLUME /etc/tor /var/lib/tor

# ORPort, DirPort, SocksPort, ObfsproxyPort, MeekPort
# EXPOSE 9001 9030 9050 54444 7002
EXPOSE 10050 10051 4431 8001 5301

ENTRYPOINT ["docker-entrypoint"]
CMD ["tor", "-f", "/etc/tor/torrc"]