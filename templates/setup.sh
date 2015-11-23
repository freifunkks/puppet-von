#!/bin/sh
is_running() {
  pidof "$1" > /dev/null
}

if ! lsmod | grep -q "batman_adv"; then
  echo "(I) Start batman-adv."
  echo "5000" >  /sys/class/net/bat0/mesh/orig_interval
fi

if ! is_running "alfred"; then
  echo "(I) Start alfred."
  alfred -i bat0 -b bat0 &> /dev/null &
fi

if ! is_running "batadv-vis"; then
  echo "(I) Start batadv-vis."
  batadv-vis -si bat0 &> /dev/null &
fi

if ! is_running "openvpn"; then
  echo "(I) Start openvpn."
  openvpn --config /etc/openvpn/uplink/AirVPN_Germany_UDP-443.ovpn > /dev/null &
fi
