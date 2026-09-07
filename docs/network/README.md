# Lake Network Baseline

## Current LAN

- Subnet: `10.2.0.0/24`
- Gateway/router: `10.2.0.1`
- DNS: currently `10.2.0.1`
- DHCP: currently provided by Orbi
- DHCP pool: `10.2.0.120` through `10.2.0.254`
- Internet: Starlink
- Upstream NAT: Starlink CGNAT

A traceroute from LEVLAKE-EDGE shows:

```text
10.2.0.1      Orbi router
100.64.0.1    Starlink CGNAT
172.16.x.x    Starlink internal network
public Internet
```

## Network infrastructure

### Orbi

Three-node Orbi system:

- one router/AP
- two satellites
- all three provide Wi-Fi
- both satellites use wired backhaul through the TP-Link switch

Current addresses:

- `10.2.0.1` — Orbi router
- `10.2.0.2` — satellite
- `10.2.0.3` — satellite

### Switch

- TP-Link TL-SG108PE
- 8-port Easy Smart PoE switch
- carries wired backhaul for both Orbi satellites

### LEVLAKE-EDGE

- Hostname: `LEVLAKE-EDGE`
- Hardware: Dynabook Portege X40-K
- Primary interface: Intel I219-V Ethernet
- MAC: `68:45:F1:21:14:4E`
- Reserved IPv4: `10.2.0.100`
- Tailscale: `100.123.190.89`
- Ethernet profile: Private

## Known reservations

- `10.2.0.2` — Orbi satellite
- `10.2.0.3` — Orbi satellite
- `10.2.0.15` — ISY994i
- `10.2.0.50` — LG webOS TV
- `10.2.0.51` — LG webOS TV
- `10.2.0.100` — LEVLAKE-EDGE

## Historical subnet collision

The Lake previously used `192.168.1.0/24`, which overlapped with the Home LAN. Tailscale also received an advertised route for Home `192.168.1.0/24`; Windows preferred the Tailscale route, causing Lake traffic for `192.168.1.x` to reach Home instead.

The issue was proven by traceroute to `192.168.1.1`, which traversed the Home TrueNAS Tailscale subnet router before reaching the Home UCG Ultra.

The current `10.2.0.0/24` Lake subnet resolves this overlap and should be retained.

## Planned network migration

Bring the old UniFi USG to the Lake and make it the authoritative router/firewall/DHCP device while keeping the current subnet.

Target topology:

```text
Starlink
   |
UniFi USG (10.2.0.1)
   |
TL-SG108PE
   |-- Orbi primary in AP mode
   |-- Orbi satellite 1
   |-- Orbi satellite 2
   |-- lake-core
   `-- LEVLAKE-EDGE
```

A local UniFi Network controller is required for the legacy USG. It may run on `lake-core` or on LEVLAKE-EDGE.

## Planned local services

- AdGuard Home for local DNS and DNS rewrites
- Mosquitto for MQTT
- Caddy for friendly local HTTPS/service names
- Dockge for container management
- UniFi Network controller

Application code should prefer hostnames/local DNS over hard-coded IP addresses once AdGuard is deployed.
