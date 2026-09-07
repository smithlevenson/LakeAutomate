# Lake Network Baseline

## Current LAN

- Subnet: `10.2.0.0/24`
- Gateway/router: `10.2.0.1`
- DNS: currently `10.2.0.1`
- DHCP: currently provided by Orbi
- DHCP pool: `10.2.0.120` through `10.2.0.254`
- Internet: Starlink
- Upstream NAT: Starlink CGNAT
- LEVLAKE-EDGE Ethernet profile: Private

A traceroute from LEVLAKE-EDGE shows:

```text
10.2.0.1      Orbi router
100.64.0.1    Starlink CGNAT
172.16.x.x    Starlink internal network
public Internet
```

The public IPv4 observed during baseline work was `74.244.55.241`, but inbound architecture must not rely on that address because Starlink is behind CGNAT.

## Network infrastructure

### Orbi

Three-node Orbi system:

- one router/AP
- two satellites
- all three provide Wi-Fi
- both satellites use **wired backhaul** through the TP-Link switch

Current addresses / MACs:

- `10.2.0.1` — Orbi router — `38:94:ED:AC:FF:3A`
- `10.2.0.2` — Orbi satellite — `38:94:ED:B2:D2:7B`
- `10.2.0.3` — Orbi satellite — `38:94:ED:B2:F1:89`

Do not interpret Orbi UI drawings as proof of wireless daisy-chain; physical topology was confirmed by the user as both satellites wired through the switch.

### Switch

- TP-Link TL-SG108PE
- 8-port Easy Smart PoE switch
- carries wired backhaul for both Orbi satellites
- remains useful after the eventual USG migration

### LEVLAKE-EDGE

- Hostname: `LEVLAKE-EDGE`
- Hardware: Dynabook Portege X40-K
- Primary interface: Intel I219-V Ethernet, 1 Gbps
- Ethernet MAC: `68:45:F1:21:14:4E`
- Reserved IPv4: `10.2.0.100`
- Tailscale: `100.123.190.89`
- Ethernet profile: Private
- RDP: available on TCP 3389 and verified before interactive login

## Known reservations

- `10.2.0.2` — Orbi satellite
- `10.2.0.3` — Orbi satellite
- `10.2.0.15` — ISY994i
- `10.2.0.50` — LG webOS TV
- `10.2.0.51` — LG webOS TV
- `10.2.0.100` — LEVLAKE-EDGE

A useful addressing convention to preserve:

```text
10.2.0.1         gateway
10.2.0.2-.9      network infrastructure
10.2.0.10-.29    controllers / automation
10.2.0.30-.99    fixed smart-home devices
10.2.0.100-.119  servers / edge systems
10.2.0.120+      dynamic DHCP
```

## Current / likely device integration candidates

Inventory work on the old subnet identified several useful future LakeAutomate targets:

- ISY994i
- LG webOS TVs
- Roku
- Phyn water device
- cameras
- Orbi / future UniFi infrastructure
- TP-Link switch status where useful
- future Shelly plugs

There was also an old client previously observed at `192.168.2.60`, supporting the recollection that an older Lake subnet once used `192.168.2.x`. Do not reuse old historical addressing merely because a legacy client still has it.

## Historical subnet collision

The Lake initially used `192.168.1.0/24`, overlapping Home.

Home also advertised `192.168.1.0/24` through Tailscale. Windows on LEVLAKE-EDGE preferred the Tailscale route:

```text
Tailscale  192.168.1.0/24  via 100.100.100.100
Ethernet   192.168.1.0/24  on-link
```

A traceroute to `192.168.1.1` proved the collision:

```text
LEVLAKE-EDGE
  -> 100.104.90.47   Home TrueNAS / Tailscale subnet router
  -> 192.168.1.1     Home UCG Ultra
```

This could make the same IP refer to the wrong physical device and was therefore unacceptable for automation.

The current `10.2.0.0/24` Lake subnet resolves the overlap. Preserve unique site subnets as a hard architectural rule.

## Tailscale policy

During the old `192.168.1.0/24` collision, route acceptance was deliberately disabled on Lake machines:

```text
tailscale up --accept-routes=false --unattended
```

The collision no longer exists after the move to `10.2.0.0/24`. Route acceptance can be reconsidered later if there is a real need, but should not be changed casually.

Tailscale is the remote access/control path. Do not depend on public inbound forwarding.

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

Migration principles:

- preserve `10.2.0.0/24`
- preserve important reservations
- put Orbis into AP mode
- make USG the only local router/firewall/DHCP authority
- verify Starlink, DNS, DHCP, Tailscale, Blue Iris, and all fixed devices after cutover
- identify exact USG model/firmware and choose a compatible UniFi Network version intentionally

A local UniFi Network controller is required for the legacy USG. It may run on `lake-core` or on LEVLAKE-EDGE.

## Planned local services

- AdGuard Home for local DNS and rewrites
- Mosquitto for MQTT
- Caddy for friendly local HTTPS/service names
- Dockge for container management
- UniFi Network controller
- optional Uptime Kuma after essentials are stable

Application code should prefer hostnames/local DNS over hard-coded IP addresses once AdGuard is deployed.

Potential names such as `lake-core`, `edge.home`, `mqtt.home`, `adguard.home`, and `dockge.home` were discussed but are **not yet final naming decisions**.

## Baseline capture

`scripts/Get-LakeNetworkBaseline.ps1` captures the repeatable raw network state including adapters, IP configuration, DNS, routes, neighbors, Wi-Fi, Tailscale, listening ports, services, network profile, Internet test, and gateway test.

Generated files:

```text
docs/network/baseline-YYYY-MM-DD_HHMM.txt
```

are intentionally ignored by Git. Durable facts from those captures should be promoted into this document rather than committing transient raw snapshots.
