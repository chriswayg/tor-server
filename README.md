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

- Prerequisites: A [Linux server hosted at a Tor friendly ISP](https://trac.torproject.org/projects/tor/wiki/doc/GoodBadISPs) with Docker installed (see [Install Docker and Docker Compose](#install-docker-and-docker-compose) below)

This command will run a Tor relay server with defaults and a randomized Nickname. The server will autostart after restarting the host system.

`docker run -d --init --name=tor-server_relay_1 --net=host -p 9001:9001 --restart=always chriswayg/tor-server`

You can set your own Nickname (only letters and numbers) and an optional Contact-Email (which will be published on the Tor network) using environment variables:
```
docker run -d --init --name=tor-server_relay_1 --net=host -p 9001:9001 \
-e TOR_NICKNAME=Tor4docker -e CONTACT_EMAIL=tor4@example.org \
--restart=always chriswayg/tor-server
```

Check with ```docker logs -f tor-server_relay_1```  If you see the message: ```[notice] Self-testing indicates your ORPort is reachable from the outside. Excellent. Publishing server descriptor.``` at the bottom after quite a while, your server started successfully.

### Customize Tor configuration
Look at the Tor manual with all [Configuration File Options](https://www.torproject.org/docs/tor-manual.html.en). Also refer to the current fully commented `torrc.default`:

`docker cp tor-server_relay_1:/etc/tor/torrc.default ./`

For more detailed customisation copy `torrc` to the host and configure the desired settings:
```
### /etc/tor/torrc ###
# Port to advertise for incoming Tor connections.
# common ports are 9001, 443
ORPort 9001
#ORPort [IPv6-address]:9001

# Run as a relay only (change policy to enable exit node)
ExitPolicy reject *:*         # no exits allowed
ExitPolicy reject6 *:*

# Run Tor only as a server (no local applications)
SocksPort 0
ControlSocket 0

# Run Tor as a regular user (do not change this)
User debian-tor
DataDirectory /var/lib/tor

## If no Nickname or ContactInfo is set, docker-entrypoint will use
## the environment variables to add Nickname/ContactInfo here
Nickname Tor4                 # only use letters and numbers
ContactInfo tor4tests@example.org
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
mkdir -vp data/keys/
docker cp tor-server_relay_1:/var/lib/tor/keys/secret_id_key ./data/keys/
docker cp tor-server_relay_1:/var/lib/tor/keys/ed25519_master_id_secret_key ./data/keys/
```

### Run Tor using docker-compose (recommended)

Adapt the example `docker-compose.yml` with your settings or clone it from [Github](https://github.com/chriswayg/tor-server).
```
version: '2.2'
services:
  relay:
    image: chriswayg/tor-server
    init: true
    restart: always
    network_mode: host
    ports:
      - "9001:9001"
      - "9030:9030"
    environment:
      ## set your Nickname here (only use letters and numbers) and an Email
      TOR_NICKNAME: Tor4
      CONTACT_EMAIL: tor4@example.org
```

##### Configure and run the Tor relay server

- Configure the `docker-compose.yml` and optionally the `torrc` file, with your individual settings. Possibly install `git` first.
```
cd /opt && git clone https://github.com/chriswayg/tor-server.git && cd tor-server
nano docker-compose.yml
```

- Start a new instance of the Tor relay server and display the logs.
```
docker-compose up -d
docker-compose logs -f
```

- As examples for running commands in the container, show the current fingerprint or enter a bash shell.
```
docker-compose exec -T relay cat /var/lib/tor/fingerprint
docker-compose exec relay bash
```

### Run Tor relay with IPv6

If your host supports IPv6, please enable it! The host system or VPS (for example Vultr) needs to have IPv6 activated. From your host server try to ping any IPv6 host: `ping6 -c 5 ipv6.google.com` Then find out your external IPv6 address:

`dig +short -6 myip.opendns.com aaaa @resolver1.ipv6-sandbox.opendns.com`

If that works fine, activate IPv6 for Docker by adding the following to the file `daemon.json` on the docker host and restarting Docker.

- use the IPv6 subnet/64 address from your provider for `fixed-cidr-v6`

```
nano /etc/docker/daemon.json

    {
    "ipv6": true,
    "fixed-cidr-v6": "21ch:ange:this:addr::/64"
    }

systemctl restart docker && systemctl status docker
```

My sample Tor relay server configurations use `network_mode: host` which makes it easier to use IPv6. - Next make your Tor relay reachable via IPv6 by adding the applicable IPv6 address at the ORPort line in your `torrc` configuration:

`ORPort [IPv6-address]:9001`

Or use the included helper script to add the main IPv6 address of your host to your `torrc`, for example:

`bash scripts/set-ipv6-in-torrc.sh config/torrc`

- Restart the container and test, that the Tor relay can reach the outside world:
```
docker-compose restart
docker-compose logs
docker-compose exec -T relay ping6 -c 5 ipv6.google.com
```

You should see something like this in the log: `[notice] Opening OR listener on [2200:2400:4400:4a61:5400:4ff:f444:e448]:9001`

- IPv6 Info for Tor and Docker:
    1. [A Tor relay operators IPv6 HOWTO](https://trac.torproject.org/projects/tor/wiki/doc/IPv6RelayHowto)
    2. [Walkthrough: Enabling IPv6 Functionality for Docker & Docker Compose](http://collabnix.com/enabling-ipv6-functionality-for-docker-and-docker-compose/)
    3. [Basic Configuration of Docker Engine with IPv6](http://www.debug-all.com/?p=128)
    4. [Docker, IPv6 and –net=”host”](http://www.debug-all.com/?p=163)
    5. [Docker Networking 101 – Host mode](http://www.dasblinkenlichten.com/docker-networking-101-host-mode/)
    5. When using the host network driver for a container, that container’s network stack is not isolated from the Docker host. If you run a container which binds to port 9001 and you use host networking, the container’s application will be available on port 9001 on the host’s IP address.

---

### Install Docker and Docker Compose

Quick installation for most operation systems (links how to install [Docker](https://docs.docker.com/install/) and [Docker Compose](https://docs.docker.com/compose/install/)):

- Install Docker

```
curl -sSL https://get.docker.com/ | CHANNEL=stable sh
systemctl status docker

systemctl enable docker
systemctl start docker
```
After the installation process is finished, you may need to enable the service and make sure it is started (e.g. CentOS 7).

- Install Docker-Compose

```
curl -L https://github.com/docker/compose/releases/download/$(curl -Ls https://www.servercow.de/docker-compose/latest.php)/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose
chmod -v +x /usr/local/bin/docker-compose
docker-compose --version
```

Please use the latest Docker engine available and do not use the engine that ships with your distros repository.

### License:
 - GPLv2 or later (c) 2018 Christian Wagner

### Guides

- [Tor Relay Guide](https://trac.torproject.org/projects/tor/wiki/TorRelayGuide)
- [Tor on Debian Installation Instructions](https://www.torproject.org/docs/debian.html.en)
- [obfs4proxy on Debian - Guide to run an obfuscated bridge to help censored users connect to the Tor network.](https://trac.torproject.org/projects/tor/wiki/doc/PluggableTransports/obfs4proxy)


[1]: https://www.torproject.org/
