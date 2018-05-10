## Tor Relay Server on Docker
[![Build Status](https://travis-ci.org/chriswayg/tor-server.svg?branch=master)](https://travis-ci.org/chriswayg/tor-server)
[![](https://images.microbadger.com/badges/image/chriswayg/tor-server.svg)](https://microbadger.com/images/chriswayg/tor-server)

##### A complete, efficient and secure Tor relay server Docker image based on Debian Stretch
*This docker image will update automatically each time the Debian Stretch base image is updated and install the latest current stable version of Tor server. It will run Tor as an unprivileged regular user, as recommended by torproject.org.*

It includes the latest Tor Debian package from torproject.org and obfs4proxy which are installed and configured according the Tor project recommendations.

The Tor network relies on volunteers to donate bandwidth. The more people who run relays, the faster the Tor network will be. If you have at least 2 megabits/s for both upload and download, please help out Tor by configuring your Tor to be a relay too.

![Tor](https://www.torproject.org/images/tor-logo.jpg "Tor logo")

[`Tor`][1] is free software and an open network that helps you defend against
traffic analysis, a form of network surveillance that threatens personal
freedom and privacy, confidential business activities and relationships, and
state security.

- Tor prevents people from learning your location or browsing habits.
- Tor is for web browsers, instant messaging clients, and more.
- Tor is free and open source for Windows, Mac, Linux/Unix, and Android

### Quickstart

- Prerequisites: A [linux server hosted at a Tor friendly ISP](https://trac.torproject.org/projects/tor/wiki/doc/GoodBadISPs) with Docker installed (see [Install Docker and Docker Compose](#install-docker-and-docker-compose) below)

This will run a Tor relay server with defaults and a randomized Nickname:

`docker run -d --init --name=tor-server_relay_1 --net=host -p 9001:9001 --restart=always chriswayg/tor-server`

You can set your own Nickname (only letters and numbers) and your Contact-Email (which will be published on the Tor network) using environment variables:
```
docker run -d --init --name=tor-server_relay_1 --net=host -p 9001:9001 \
-e TOR_NICKNAME=Tor4docker -e CONTACT_EMAIL=tor4@example.org \
--restart=always chriswayg/tor-server
```

Check with ```docker logs tor-server_relay_1```. If you see the message ```[notice] Self-testing indicates your ORPort is reachable from the outside. Excellent. Publishing server descriptor.``` at the bottom after quite a while, your server started successfully.

### Customize Tor configuration
Look at the Tor manual with all [Configuration File Options](https://www.torproject.org/docs/tor-manual.html.en). Also refer to the current fully commented `torrc.default`:

`docker cp tor-server_relay_1:/etc/torrc/torrc.default ./`

For more detailed customisation copy `./torrc` to the host and configure the desired settings:
```
### /etc/torrc ###

# Server's public IP Address (usually automatic)
#Address 10.10.10.10

# Port to advertise for incoming Tor connections.
# common ports are 9001, 443
ORPort 9001

# Mirror directory information for others (optional)
# common ports are 9030, 80
#DirPort 9030

# Run as a relay only (not as an exit node)
ExitPolicy reject *:*         # no exits allowed

# Set limits
#RelayBandwidthRate 1024 KB   # Throttle traffic to
#RelayBandwidthBurst 2048 KB  # But allow bursts up to
#MaxMemInQueues 512 MB        # Limit Memory usage to

# Run Tor as obfuscated bridge
#ServerTransportPlugin obfs4 exec /usr/bin/obfs4proxy
#ServerTransportListenAddr obfs4  0.0.0.0:54444
#ExtORPort auto
#BridgeRelay 1

# Run Tor only as a server (no local applications)
SocksPort 0

# Run Tor as a regular user (do not change this)
User debian-tor
DataDirectory /var/lib/tor

## If no Nickname or ContactInfo is set, docker-entrypoint will use
## the environment variables to add Nickname/ContactInfo here
Nickname Tor4                 # only use letters and numbers
ContactInfo email@example.org
```

#### Run Tor with mounted `torrc`

Mount your customized `torrc` into the container. You can reuse the identity keys from a previous Tor relay server installation, to continue with the same Fingerprint and ID.
```
docker run -d --init --name=tor-server_relay_1 --net=host -p 9001:9001 -p 9030:9030 \
-v $PWD/torrc:/etc/tor/torrc \
-v $PWD/secret_id_key:/var/lib/tor/keys/secret_id_key -v $PWD/ed25519_master_id_secret_key:/var/lib/tor/ed25519_master_id_secret_key \
--restart=always chriswayg/tor-server
```

### Move or upgrade the Tor relay

When upgrading your Tor relay, or moving it on a different computer, the important part is to keep the same identity keys. Keeping backups of the identity keys so you can restore a relay in the future is the recommended way to ensure the reputation of the relay won't be wasted.

```
docker cp tor-server_relay_1:/var/lib/tor/keys/secret_id_key ./
docker cp tor-server_relay_1:/var/lib/tor/keys/ed25519_master_id_secret_key ./
```

### Run Tor using docker-compose

Adapt this example `docker-compose.yml` with your settings or clone it from [Github](https://github.com/chriswayg/tor-server).
```
version: '2.2'
services:
  relay:
    image: chriswayg/tor-server
    init: true
    restart: always
    ports:
      - "9001:9001"
    environment:
      ## set your Nickname here (only use letters and numbers)
      TOR_NICKNAME: Tor4docker
      CONTACT_EMAIL: tor4@example.org
```

##### Configure and run the Tor relay server

- Configure the `docker-compose.yml` and optionally the `torrc` file, with your individual settings. Possibly install `git` first.
```
git clone https://github.com/chriswayg/tor-server.git && cd tor-server
nano docker-compose.yml
```

- Start a new instance of the Tor relay server and display the logs.
```
docker-compose up -d
docker-compose logs -f
```

- As an example for running commands in the container, show the current fingerprint.
```
docker-compose exec -T relay cat /var/lib/tor/fingerprint
```

### Run Tor relay with IPv6

The host system or VPS (for example Vultr) needs to have IPv6 activated. From your server try to ping any IPv6 host: `ping6 google.com`

If that worked fine, make your Tor relay reachable via IPv6 by adding an additional ORPort line to your `torrc` configuration (example for ORPort 9001):

`ORPort [IPv6-address]:9001`

Additionally activate IPv6 for Docker by editing/creating the file `daemon.json` on the docker host and restarting Docker.

- use the IPv6 subnet/64 address from your provider for `fixed-cidr-v6`

```
$ nano /etc/docker/daemon.json

{
"ipv6": true,
"fixed-cidr-v6": "2100:1900:4400:4abc::/64"
}

$ systemctl restart docker
```

### Install Docker and Docker Compose

**1\.** Learn how to install [Docker](https://docs.docker.com/install/) and [Docker Compose](https://docs.docker.com/compose/install/).

Quick installation for most operation systems:

- Docker
```
curl -sSL https://get.docker.com/ | CHANNEL=stable sh
# After the installation process is finished, you may need to enable the service and make sure it is started (e.g. CentOS 7)
systemctl status docker.service
systemctl enable docker.service
systemctl start docker.service
```

- Docker-Compose
```
curl -L https://github.com/docker/compose/releases/download/$(curl -Ls https://www.servercow.de/docker-compose/latest.php)/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose
chmod -v +x /usr/local/bin/docker-compose
docker-compose --version
```

Please use the latest Docker engine available and do not use the engine that ships with your distros repository.

### License:
 - GPLv3 (c) 2018 Christian Wagner

### Guides

- [Tor Relay Guide](https://trac.torproject.org/projects/tor/wiki/TorRelayGuide)
- [Tor on Debian Installation Instructions](https://www.torproject.org/docs/debian.html.en)
- [obfs4proxy on Debian - Guide to run an obfuscated bridge to help censored users connect to the Tor network.](https://trac.torproject.org/projects/tor/wiki/doc/PluggableTransports/obfs4proxy)


[1]: https://www.torproject.org/
