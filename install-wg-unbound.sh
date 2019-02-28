if [[ -z $1 ]]; then
  echo "Public server IP required. ./install-wg.sh pu.bl.ic.ip"
  exit 1
fi
SERVER_HOST=$1

# Setup wireguard

echo "deb http://deb.debian.org/debian/ unstable main" > /etc/apt/sources.list.d/unstable.list
printf 'Package: *\nPin: release a=unstable\nPin-Priority: 90\n' > /etc/apt/preferences.d/limit-unstable
apt update && apt install wireguard qrencode iptables-persistent -y

WG_FILE="/etc/wireguard/wg0.conf"
SERVER_PORT=51820
PRIVATE_SUBNET="10.0.1.0/24"
SERVER_ADDRESS="10.0.1.1"
SERVER_KEY=$(wg genkey)
SERVER_PUB_KEY=$( echo $SERVER_KEY| wg pubkey )
LAPTOP_KEY=$(wg genkey)
LAPTOP_PUB_KEY=$( echo $LAPTOP_KEY | wg pubkey )
LAPTOP_ADDRESS="10.0.1.2"
MOBILE_KEY=$(wg genkey)
MOBILE_PUB_KEY=$( echo $MOBILE_KEY | wg pubkey )
MOBILE_ADDRESS="10.0.1.3"

mkdir -p /etc/wireguard
touch $WG_FILE && chmod 600 $WG_FILE

echo "[Interface]
Address = $SERVER_ADDRESS
ListenPort = $SERVER_PORT
PrivateKey = $SERVER_KEY
[Peer]
PublicKey = $LAPTOP_PUB_KEY
AllowedIPs = $LAPTOP_ADDRESS
[Peer]
PublicKey = $MOBILE_PUB_KEY
AllowedIPs = $MOBILE_ADDRESS" > $WG_FILE

echo "[Interface]
PrivateKey = $LAPTOP_KEY
Address = $LAPTOP_ADDRESS
DNS = $SERVER_ADDRESS
[Peer]
PublicKey = $SERVER_PUB_KEY
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $SERVER_HOST:$SERVER_PORT" > $HOME/wg0-laptop.conf
cat $HOME/wg0-laptop.conf

echo "[Interface]
PrivateKey = $MOBILE_KEY
Address = $MOBILE_ADDRESS
DNS = $SERVER_ADDRESS
[Peer]
PublicKey = $SERVER_PUB_KEY
AllowedIPs = 0.0.0.0/0, ::/0
Endpoint = $SERVER_HOST:$SERVER_PORT" > $HOME/wg0-mobile.conf

qrencode -t ansiutf8 < $HOME/wg0-mobile.conf

echo "net.ipv4.ip_forward=1
net.ipv6.conf.all.forwarding=1" >> /etc/sysctl.conf
sysctl -p

# Setup unbound DNS + block ads and tracking

apt update && apt install unbound -y
curl -o /etc/unbound/root.hints https://www.internic.net/domain/named.cache

curl -o ads https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts
cat ads | grep '^0\.0\.0\.0' | awk '{print "local-zone: \""$2"\" redirect\nlocal-data: \""$2" A 0.0.0.0\""}' > ads.conf
cp ads.conf /etc/unbound/

echo "
server:
    verbosity: 1
    interface: 0.0.0.0
    interface: ::0

    port: 53
    do-ip4: yes
    do-ip6: yes
    do-udp: yes
    do-tcp: yes

    access-control: 10.0.1.0/24 allow
    access-control: 127.0.0.0/8 allow

    root-hints: "/etc/unbound/root.hints"
    hide-identity: yes
    hide-version: yes
    harden-glue: yes
    harden-dnssec-stripped: yes
    use-caps-for-id: yes
    cache-min-ttl: 3600
    cache-max-ttl: 86400
    prefetch: yes
    num-threads: 1
    msg-cache-slabs: 2
    rrset-cache-slabs: 2
    infra-cache-slabs: 2
    key-cache-slabs: 2
    rrset-cache-size: 64m
    msg-cache-size: 32m
    so-rcvbuf: 1m
    unwanted-reply-threshold: 10000
    do-not-query-localhost: no
    val-clean-additional: yes

include: /etc/unbound/ads.conf
" > /etc/unbound/unbound.conf

# Configure Firewall

iptables -A FORWARD -s $PRIVATE_SUBNET -j ACCEPT
iptables -t nat -A POSTROUTING -s $PRIVATE_SUBNET -j MASQUERADE
iptables -A INPUT -p udp -s $PRIVATE_SUBNET -m udp --dport 53 -j ACCEPT
iptables -A OUTPUT -p udp -s $PRIVATE_SUBNET -m udp --sport 53 -j ACCEPT
iptables -A INPUT -p tcp -s $PRIVATE_SUBNET -m tcp --dport 53 -j ACCEPT
iptables -A OUTPUT -p tcp -s $PRIVATE_SUBNET -m tcp --sport 53 -j ACCEPT
iptables-save > /etc/iptables/rules.v4

# Start services

systemctl enable wg-quick@wg0.service
systemctl start wg-quick@wg0.service
systemctl enable unbound.service
systemctl start unbound.service
