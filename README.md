## Tor Relay Server on Docker (Debian)
[![Build Status](https://travis-ci.org/chriswayg/tor-server.svg?branch=master)](https://travis-ci.org/chriswayg/tor-server)
[![](https://images.microbadger.com/badges/image/chriswayg/tor-server.svg)](https://microbadger.com/images/chriswayg/tor-server)

#### A complete, efficient and secure Tor relay server Docker image
*This docker image will update automatically each time the Debian Stretch base image is updated and install the latest current stable version of Tor server. It will run Tor as an unprivileged regular user, as recommended by torproject.org.*

It includes the latest Tor Debian package from torproject.org which is installed and configured according the Tor project recommendations. Additionally it can be run as a hidden bridge using and obfs4proy as well as meek.

The Tor network relies on volunteers to donate bandwidth. The more people who run relays, the faster the Tor network will be. If you have at least 2 megabits/s for both upload and download, please help out Tor by configuring your server to be a Tor relay too.

![Tor](https://www.torproject.org/images/tor-logo.jpg "Tor logo")

[Tor](https://www.torproject.org) is free software and an open network that helps you defend against
traffic analysis, a form of network surveillance that threatens personal
freedom and privacy, confidential business activities and relationships, and
state security.

- Tor prevents people from learning your location or browsing habits.
- Tor is for web browsers, instant messaging clients, and more.
- Tor is free and open source for Windows, Mac, Linux/Unix, and Android

### Quickstart - Tor relay server in minutes

- Prerequisites: A [Linux server hosted at a Tor friendly ISP](https://trac.torproject.org/projects/tor/wiki/doc/GoodBadISPs) with Docker installed (see [Install Docker and Docker Compose](#install-docker-and-docker-compose) below)

Create a directory for your Tor server data. Then set your own Nickname (only letters and numbers) and an optional contact Email (which will be published on the Tor network) using environment variables:
```
mkdir -vp tor-data && \
docker run -d --init --name=tor-server_relay_1 --net=host \
-e TOR_NICKNAME=Tor4 \
-e CONTACT_EMAIL=tor4@example.org \
-v $PWD/tor-data:/var/lib/tor \
--restart=always chriswayg/tor-server
```

This command will run a Tor relay server with a safe default configuration (not as an exit node). The server will autostart after restarting the host system. If you do not change the default Nickname 'Tor4', the startup script will add a randomized, pronouncable suffix to create a unique name. All Tor data will be preserved in the mounted Data Directory, even if you upgrade or remove the container.

Check with ```docker logs -f tor-server_relay_1```  If you see the message: ```[notice] Self-testing indicates your ORPort is reachable from the outside. Excellent. Publishing server descriptor.``` at the bottom after a while, your server started successfully. The wait a bit longer and search for your server here: [Relay Search](https://metrics.torproject.org/rs.html)

### Customize Tor configuration
You may want to configure additional options to control your monthly data usage, or to run Tor as a hidden obfuscated bridge. Look at the Tor manual with all [Configuration File Options](https://www.torproject.org/docs/tor-manual.html.en). Also refer to a recent fully commented `torrc.default`:

`docker cp tor-server_relay_1:/etc/tor/torrc.default ./`

For customisation copy `torrc` to the host and configure the desired settings.
```
##=================== /etc/torrc =====================##
# Run Tor as a regular user (do not change this)
User debian-tor
DataDirectory /var/lib/tor

# Port to advertise for incoming Tor connections.
ORPort 9001                 # common ports are 9001, 443
#ORPort [IPv6-address]:9001

# Mirror directory information for others
DirPort 9030

# Run as a relay only (change policy to enable exit node)
ExitPolicy reject *:*       # no exits allowed
ExitPolicy reject6 *:*

# Run Tor only as a server (no local applications)
SocksPort 0
ControlSocket 0

#Nickname Tor4example         # only use letters and numbers
#ContactInfo tor4@example.org
```

#### Run Tor with a mounted `torrc` configuration

Mount your customized `torrc` from the current directory of the host into the container with this command:
```
nano torrc

mkdir -vp tor-data && \
docker run -d --init --name=tor-server_relay_1 --net=host \
-e TOR_NICKNAME=Tor4 \
-e CONTACT_EMAIL=tor4@example.org \
-v $PWD/tor-data:/var/lib/tor \
-v $PWD/torrc:/etc/tor/torrc \
--restart=always chriswayg/tor-server
```

### Move or upgrade the Tor relay

When upgrading your Tor relay, or moving it on a different computer, the important part is to keep the same identity keys. Keeping backups of the identity keys so you can restore a relay in the future is the recommended way to ensure the reputation of the relay won't be wasted.

```
mkdir -vp tor-data/keys/ && \
docker cp tor-server_relay_1:/var/lib/tor/keys/secret_id_key ./tor-data/keys/ && \
docker cp tor-server_relay_1:/var/lib/tor/keys/ed25519_master_id_secret_key ./tor-data/keys/
```
You can also reuse these identity keys from a previous Tor relay server installation, to continue with the same Fingerprint and ID, by inserting the following lines, in the previous command:
```
-v $PWD/tor-data/keys/secret_id_key:/var/lib/tor/keys/secret_id_key \
-v $PWD/tor-data/keys/ed25519_master_id_secret_key:/var/lib/tor/ed25519_master_id_secret_key \
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
    environment:
      TOR_NICKNAME: Tor4
      CONTACT_EMAIL: tor4@example.org
    volumes:
      - ./tor-data/:/var/lib/tor/
      - ./torrc:/etc/tor/torrc

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

If your host supports IPv6, please enable it! The host system or VPS (for example Vultr) needs to have IPv6 activated. From your host server try to ping any IPv6 host: `ping6 -c 5 ipv6.google.com` Then find out your external IPv6 address with this command:

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

`bash scripts/set-ipv6-in-torrc.sh torrc`

- Restart the container and test, that the Tor relay can reach the outside world:
```
docker-compose restart
docker-compose logs
docker-compose exec -T relay ping6 -c 5 ipv6.google.com
```

You should see something like this in the log: `[notice] Opening OR listener on [2200:2400:4400:4a61:5400:4ff:f444:e448]:9001`

- IPv6 info for Tor and Docker:
    1. [A Tor relay operators IPv6 HOWTO](https://trac.torproject.org/projects/tor/wiki/doc/IPv6RelayHowto)
    2. [Walkthrough: Enabling IPv6 Functionality for Docker & Docker Compose](http://collabnix.com/enabling-ipv6-functionality-for-docker-and-docker-compose/)
    3. [Basic Configuration of Docker Engine with IPv6](http://www.debug-all.com/?p=128)
    4. [Docker, IPv6 and –net=”host”](http://www.debug-all.com/?p=163)
    5. [Docker Networking 101 – Host mode](http://www.dasblinkenlichten.com/docker-networking-101-host-mode/)
    5. When using the host network driver for a container, that container’s network stack is not isolated from the Docker host. If you run a container which binds to port 9001 and you use host networking, the container’s application will be available on port 9001 on the host’s IP address.

---

### Install Docker and Docker Compose

Quick installation for most operation systems (with links how to install [Docker](https://docs.docker.com/install/) and [Docker Compose](https://docs.docker.com/compose/install/):

- Install Docker

```
curl -sSL https://get.docker.com/ | CHANNEL=stable sh
systemctl status docker
```

After the installation process is finished, you may need to enable the service and make sure it is started (e.g. CentOS 7).

```
systemctl enable docker
systemctl start docker
```

- Install Docker-Compose

```
curl -L https://github.com/docker/compose/releases/download/$(curl -Ls https://www.servercow.de/docker-compose/latest.php)/docker-compose-$(uname -s)-$(uname -m) > /usr/local/bin/docker-compose
chmod -v +x /usr/local/bin/docker-compose
docker-compose --version
```

Please use the latest Docker engine available and do not use the engine that ships with your distro's repository.

### Guides

- [Tor Relay Guide](https://trac.torproject.org/projects/tor/wiki/TorRelayGuide)
- [Tor on Debian Installation Instructions](https://www.torproject.org/docs/debian.html.en)
- [Torproject - git repo](https://github.com/torproject/tor)
- [obfs4proxy on Debian - Guide to run an obfuscated bridge to help censored users connect to the Tor network.](https://trac.torproject.org/projects/tor/wiki/doc/PluggableTransports/obfs4proxy)
- [obfs4 - The obfourscator - Github](https://github.com/Yawning/obfs4)
- [How to use the “meek” pluggable transport](https://blog.torproject.org/how-use-meek-pluggable-transport)
- [meek-server for Tor meek bridge](https://github.com/arlolra/meek/tree/master/meek-server)

### License:
 - MIT

 * For a very similar image based on Alpine use `tor-alpine`:*
 - https://hub.docker.com/r/chriswayg/tor-alpine
 - https://github.com/chriswayg/tor-alpine
