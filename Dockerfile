# Dockerfile for Tor Relay Server with obfs4proxy (Multi-Stage build)
FROM golang:stretch AS go-build

# Build /go/bin/obfs4proxy & /go/bin/meek-server
RUN go get -v git.torproject.org/pluggable-transports/obfs4.git/obfs4proxy \
 && go get -v git.torproject.org/pluggable-transports/meek.git/meek-server \
 && cp -rv /go/bin /usr/local/

FROM debian:stretch-slim
MAINTAINER Christian chriswayg@gmail.com

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
 # Add torproject.org Debian repository for stable Tor version \
 && for server in \
    		ha.pool.sks-keyservers.net \
    		hkp://keyserver.ubuntu.com:80 \
    		hkp://p80.pool.sks-keyservers.net:80 \
        ipv4.pool.sks-keyservers.net \
        keys.gnupg.net \
    		pgp.mit.edu; \
  	do \
    		echo "Fetching GPG key $GPGKEY from $server" \
     && apt-key adv --keyserver "$server" --keyserver-options timeout=10 --recv-keys "$GPGKEY" \
     && found=yes \
     && break; \
	  done; \
	  test -z "$found" && echo >&2 "error: failed to fetch GPG key $GPGKEY" && exit 1; \
    echo "deb https://deb.torproject.org/torproject.org stretch main"   >  /etc/apt/sources.list.d/tor-apt-sources.list \
 && echo "deb-src https://deb.torproject.org/torproject.org stretch main" >> /etc/apt/sources.list.d/tor-apt-sources.list \
 && echo "deb http://deb.torproject.org/torproject.org obfs4proxy main" >> /etc/apt/sources.list.d/tor-apt-sources.list \
 # Install tor with GeoIP and obfs4proxy & backup torrc \
 && apt-get update \
 && apt-get install --no-install-recommends --no-install-suggests -y \
        pwgen \
        iputils-ping \
        tor \
        tor-geoipdb \
        deb.torproject.org-keyring \
 && mkdir -pv /usr/local/etc/tor/ \
 && mv -v /etc/tor/torrc /usr/local/etc/tor/torrc.sample \
 && apt-get purge --auto-remove -y \
        apt-transport-https \
        dirmngr \
        apt-utils \
        gnupg \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/* \
 # Rename Debian unprivileged user to tord \
 && usermod -l tord debian-tor \
 && groupmod -n tord debian-tor

# Copy obfs4proxy & meek-server
COPY --from=go-build /usr/local/bin/ /usr/local/bin/

# Copy Tor configuration file
COPY ./torrc /etc/tor/torrc

# Copy docker-entrypoint
COPY ./scripts/ /usr/local/bin/

# Persist data
VOLUME /etc/tor /var/lib/tor

# ORPort, DirPort, SocksPort, ObfsproxyPort, MeekPort
EXPOSE 9001 9030 9050 54444 7002

ENTRYPOINT ["docker-entrypoint"]
CMD ["tor", "-f", "/etc/tor/torrc"]
