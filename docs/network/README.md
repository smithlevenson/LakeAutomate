# Lake Network Baseline

## Current LAN

- Subnet: `10.2.0.0/24`
- Gateway/router: `10.2.0.1`
- DNS: currently `10.2.0.1`
- DHCP: currently provided by Orbi
- DHCP pool: currently `10.2.0.120` through `10.2.0.254`
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

Three-node Orbi system today:

- one router/AP
- two satellites
- all three provide Wi-Fi
- both satellites use wired backhaul through the TP-Link switch

Current addresses / MACs:

- `10.2.0.1` — Orbi router today; future USG gateway — `38:94:ED:AC:FF:3A`
- `10.2.0.2` — Orbi satellite — `38:94:ED:B2:D2:7B`
- `10.2.0.3` — Orbi satellite — `38:94:ED:B2:F1:89`

Future plan:

- current Orbi router becomes AP at `10.2.0.4`
- existing satellites remain `.2` and `.3`
- `.5` remains available for another Orbi if useful

Do not interpret Orbi UI drawings as proof of wireless daisy-chain; physical topology was confirmed as wired through the switch.

### Switch

- TP-Link TL-SG108PE
- reserved at `10.2.0.8`
- 8-port Easy Smart PoE switch
- supports 802.1Q VLAN/PVID configuration
- carries wired backhaul for the Orbi satellites
- remains useful after the eventual USG migration

Do not configure VLANs until physical switch ports are mapped and the USG cutover is ready.

### LEVLAKE-EDGE

- Hostname: `LEVLAKE-EDGE`
- Hardware: Dynabook Portege X40-K
- Primary interface: Intel I219-V Ethernet, 1 Gbps
- Ethernet MAC: `68:45:F1:21:14:4E`
- Reserved IPv4: `10.2.0.100`
- Tailscale: `100.123.190.89`
- Ethernet profile: Private
- RDP: available on TCP 3389 and verified before interactive login
- current Tailscale subnet router for `10.2.0.0/24`

## Intentional reservations

```text
10.2.0.1    gateway today (Orbi); future USG
10.2.0.2    Orbi satellite
10.2.0.3    Orbi satellite
10.2.0.4    future Orbi AP address for today's Orbi router
10.2.0.5    reserved for possible additional Orbi
10.2.0.8    TP-Link TL-SG108PE
10.2.0.10   lake-core (reserved; hardware TBD)
10.2.0.11   Home Assistant VM
10.2.0.15   ISY994i
10.2.0.20   Phyn water device
10.2.0.21   YoLink hub
10.2.0.50   LG webOS TV
10.2.0.51   LG webOS TV
10.2.0.52   DirecTV
10.2.0.53   Roku (Master; legacy hostname LAKEDEN)
10.2.0.60   Drive camera
10.2.0.61   Garage IP camera / viewer on port 80
10.2.0.100  LEVLAKE-EDGE
```

Addressing convention:

```text
10.2.0.1         gateway
10.2.0.2-.9      network infrastructure
10.2.0.10-.29    controllers / automation
10.2.0.30-.49    reserved/future fixed devices
10.2.0.50-.59    media / TVs
10.2.0.60-.79    cameras
10.2.0.80-.99    future fixed appliances
10.2.0.100-.119  computers / edge systems
10.2.0.120+      dynamic DHCP
```

Preserve `10.2.0.0/24` through the USG migration.

## Device notes

- YoLink hub (`10.2.0.21`) currently supports sensors on the hot tub and refrigerator; expansion is expected. It may move to an IoT VLAN later after its Home Assistant/integration path is verified.
- Phyn (`10.2.0.20`) may need a like-for-like replacement; verify the exact replacement path before depending on it for new logic.
- Garage IP camera is `10.2.0.61`, with its local viewer on port 80.
- Home Assistant is `10.2.0.11` and currently listens on port 80.

## Historical subnet collision

The Lake initially used `192.168.1.0/24`, overlapping Home. Home also advertised `192.168.1.0/24` through Tailscale via TrueNAS.

A traceroute to `192.168.1.1` from the Lake proved traffic was being sent to the Home UCG Ultra through the Tailscale subnet router instead of to the local Orbi.

The move to `10.2.0.0/24` resolved the overlap. Unique site subnets are a hard architectural rule.

## Tailscale routing and DNS

LEVLAKE-EDGE now advertises:

```text
10.2.0.0/24
```

The route is approved in the Tailscale admin console. Windows IPv4 forwarding is enabled on:

```text
Tailscale
vEthernet (Lake LAN)
```

Remote clients have successfully reached Lake services through this route, including Home Assistant, the TP-Link switch, and camera web interfaces.

LEVLAKE-EDGE also accepts the Home subnet route, so Home `192.168.1.0/24` resources remain reachable from the Lake through Tailscale.

Home split DNS is already configured in Tailscale:

```text
home -> 192.168.1.12
```

Once Lake AdGuard is deployed on `lake-core`, add:

```text
lake -> 10.2.0.10
```

Expected future names include:

```text
ha.lake
edge.lake
isy.lake
switch.lake
```

Do not enable broad/global DNS override merely to support these names; use split DNS.

## Planned network migration

Target topology:

```text
Starlink
   |
UniFi USG (10.2.0.1)
   |
TL-SG108PE (10.2.0.8)
   |-- Orbi APs
   |-- lake-core (10.2.0.10)
   `-- LEVLAKE-EDGE (10.2.0.100)
```

Migration principles:

- preserve `10.2.0.0/24`
- preserve intentional reservations
- make USG the only local router/firewall/DHCP authority
- put Orbis into AP mode
- map switch ports before VLAN changes
- verify Starlink, DNS, DHCP, Tailscale, Home Assistant, Blue Iris, and fixed devices after cutover
- identify exact USG model/firmware and compatible UniFi Network version intentionally

A local UniFi Network controller is required for the legacy USG. It may run on `lake-core` or LEVLAKE-EDGE.

## Planned local services

`lake-core` is reserved at `10.2.0.10` for boring always-on infrastructure:

- AdGuard Home
- Mosquitto
- Caddy
- Dockge
- UniFi Network controller
- optional Uptime Kuma

Application code should prefer `.lake` DNS names over hard-coded IP addresses once AdGuard is deployed.

## Baseline capture

`scripts/Get-LakeNetworkBaseline.ps1` captures repeatable raw network state including adapters, IP configuration, DNS, routes, neighbors, Wi-Fi, Tailscale, listening ports, services, network profile, Internet test, and gateway test.

Generated files:

```text
docs/network/baseline-YYYY-MM-DD_HHMM.txt
```

are intentionally ignored by Git. Durable facts from those captures should be promoted into this document rather than committing transient raw snapshots.
