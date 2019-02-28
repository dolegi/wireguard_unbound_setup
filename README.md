# Wireguard and Unbound DNS install script
Installs and configures wireguard and unbound on a debian based server.
Redirects ad and malware from this list `https://raw.githubusercontent.com/StevenBlack/hosts/master/hosts`


# Install steps
- scp to debian server `scp install-wg-unbound.sh user@ip:/dir`
- run on server `./install-wg-unbound.sh pu.bl.ic.ip`
- copy wireguard laptop config (output above the QR code) to laptop wireguard client
- scan QR code on wireguard mobile client

# References

- https://www.wireguard.com
- https://www.nlnetlabs.nl/projects/unbound/about/
- https://calomel.org/unbound_dns.html
- https://deadc0de.re/articles/unbound-blocking-ads.html
- https://github.com/StevenBlack/hosts
