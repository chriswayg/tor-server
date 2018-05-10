#!/bin/bash
set -o errexit
# usage: scripts/set-ipv6-in-torrc.sh /host-path/to/torrc

if [ $# -eq 1 ]; then
   # Check if the input file actually exists.
   if ! [[ -f "$1" ]]; then
     echo "The file $1 does not exist!"
     exit 1
   fi
else
    echo "Usage: $0 [/host-path/to/torrc]"
    exit 1
fi

# Try to automatically set external ipv6, if none has been set in torrc
if ! grep -q '^ORPort \[' ${1}; then
    IPV6=$(dig +short -6 myip.opendns.com aaaa @resolver1.ipv6-sandbox.opendns.com)
    echo "Setting IPv6 on ORPort 9001: ${IPV6}"
    echo -e "\nORPort [${IPV6}]:9001" >> ${1}
else
    echo "IPv6 has been set already!"
fi
