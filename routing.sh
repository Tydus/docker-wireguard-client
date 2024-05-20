#!/bin/sh

# Debug output
set -x

# Exit on error
set -e

docker_network_gw="$(ip route | awk '/default/{print $3}')"
docker_network_gw6="$(ip -6 route | awk '/default/{print $3}')"

# Add the wireguard endpoints from config file

tr -d ' ' /etc/wireguard/wg0.conf | grep -Po '[^#]*Endpoint=\K.*' | while read peer; do 
    case "$peer" in
        [*]:*) 
            if [ -n "$docker_network_gw6" ]; then
                ip="$(echo "$peer" | awk -F'[][]' '{print $2}')"
                ip route add $ip/128 via $docker_network_gw6 dev eth0
            fi
            echo "Added $ip/128 via default gateway"
            ;;
        *.*.*.*:*)
            # XXX: a.b.c.domain:1234 will fail here.
            if [ -n "$docker_network_gw" ]; then
                ip="$(echo "$peer" | cut -d: -f1)"
                ip route add $ip/32 via $docker_network_gw dev eth0
            fi
            echo "Added $ip/32 via default gateway"
            ;;
        *)
            echo "Warning: domain name for endpoint is not supported. You should manually add potential endpoint IP addresses to \$NET_LOCAL or \$NET6_LOCAL"
            ;;
    esac

done


if [ -n "$NET_LOCAL" -a -n "$docker_network_gw" ]; then
  docker_network_gw="$(ip route | awk '/default/{print $3}')"
  ip route add $NET_LOCAL via $docker_network_gw dev eth0
fi

if [ -n "$NET6_LOCAL" -a -n "$docker_network_gw6" ]; then
  docker_network_gw="$(ip -6 route | awk '/default/{print $3}')"
  ip route add $NET6_LOCAL via $docker_network_gw dev eth0
fi
