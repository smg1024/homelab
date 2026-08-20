---
icon: fontawesome/solid/filter-circle-xmark
---

# DNS

AdGuard Home runs on `yggdrasil` and filters DNS for the private home LAN.
The ipTIME router remains the DHCP server and advertises the resolver to
clients. AdGuard Home does not provide DHCP.

## Network contract

| Item | Value |
| --- | --- |
| Router mode and gateway | ipTIME NAT, `192.168.0.1/24` |
| LAN | `192.168.0.0/24` |
| yggdrasil reservation | `192.168.0.53` on `enp2s0` |
| DNS listener | TCP and UDP `192.168.0.53:53` |
| Admin UI | HTTP `:3000`; use `https://adguardhome.ridewithmin.com` over the tailnet |

The firewall matches the LAN source range and the reserved destination
address. If yggdrasil receives any other address, LAN DNS fails closed. The
ipTIME router also blocks unsolicited WAN traffic unless a port-forward is
added. Do not create a DNS or admin UI port-forward.

!!! warning "The DHCP reservation is required"
    Reserve `192.168.0.53` before deployment. Do not change the module to match
    a temporary DHCP lease. Its destination check is an intentional guard
    against address drift.

## Preflight after a network change

Recheck the live network before deploying this module after a move, router
replacement, or subnet change:

```bash
ssh yggdrasil 'ip -brief address show dev enp2s0; ip -4 route show default'
ssh yggdrasil 'nmcli -f GENERAL.DEVICE,IP4.ADDRESS,IP4.GATEWAY,DHCP4.OPTION device show enp2s0'
```

The interface must be `enp2s0`, the LAN must be `192.168.0.0/24`, and the
gateway must be `192.168.0.1`. If any of these differ, update the network
contract and firewall together. A different host address means the router
reservation is missing or wrong.

## Configure ipTIME

1. Open `http://192.168.0.1` and enter the management tool.
2. Confirm the ISP cable uses the WAN port, the router LAN is
   `192.168.0.1/24`, and its DHCP server is enabled.
3. Reserve `192.168.0.53` for yggdrasil's `enp2s0` MAC address. Read the
   current address with `ssh yggdrasil 'cat /sys/class/net/enp2s0/address'`.
4. Reconnect or renew yggdrasil's lease, then verify it:

    ```bash
    ssh yggdrasil 'ip -4 address show dev enp2s0'
    ```

Do not deploy the service until this command shows `192.168.0.53/24`. Do not
configure WAN port forwarding for TCP or UDP `:53` or for the admin UI.

## First setup

The NixOS module deliberately leaves AdGuard Home in first-run mode. This
keeps the admin password out of Git and the Nix store.

1. Deploy through the normal PR and CI/CD flow.
2. Forward the setup UI over SSH:

    ```bash
    ssh -L 3005:127.0.0.1:3000 yggdrasil
    ```

3. Open `http://127.0.0.1:3005`.
4. Select all interfaces and port `3000` for the admin UI.
5. Select all interfaces and port `53` for DNS.
6. Create the administrator account with a unique password.

AdGuard Home stores its configuration, credentials, query statistics, and
filter state in `/var/lib/AdGuardHome`. Deployments preserve this directory,
but no backup job currently protects it.

Tailnet clients open the dashboard at
`https://adguardhome.ridewithmin.com`. The hostname is absent from Cloudflare
Tunnel and resolves directly to yggdrasil's Tailscale IPv4 address. Caddy
rejects requests from outside the tailnet.

## Advertise DNS through DHCP

In the ipTIME DHCP server settings, advertise `192.168.0.53` as the primary
DNS server. Leave secondary DNS empty. If you configure a public secondary
resolver, clients may bypass AdGuard Home.

Some ipTIME firmware only exposes the router's own upstream DNS setting. In
that case, set the router's primary DNS to `192.168.0.53`. Filtering still
works, but AdGuard Home sees the router rather than individual clients.

Renew a client lease after changing DHCP. Existing leases keep the old DNS
setting until they renew.

## Verify

Run these checks from a LAN client:

```bash
nslookup example.com 192.168.0.53
dig @192.168.0.53 example.com
```

Then open the AdGuard Home query log through the SSH tunnel and confirm the
request appears. Test one domain from an enabled filter list to confirm that
filtering, not only forwarding, works.

On yggdrasil:

```bash
systemctl is-active adguardhome
sudo ss -luntp 'sport = :53 or sport = :3000'
sudo journalctl -u adguardhome -n 100 --no-pager
```

## Failure behavior

AdGuard Home is the only household resolver. If yggdrasil is down, clients
lose DNS until it returns or someone changes the router DNS setting. Do not
add a public secondary resolver as a hidden bypass. Run a second AdGuard Home
instance if the household needs DNS redundancy.
