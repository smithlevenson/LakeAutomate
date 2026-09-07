# Architecture

## Purpose

LakeAutomate is the **local control plane** for the lake. It owns device integration, automation, telemetry, and local operational state. LevLake is the user-facing website/application and should consume normalized state or request high-level actions rather than directly controlling devices.

## Principle

> **LevLake displays and requests. LakeAutomate observes and controls.**

This separation keeps the property functional during Starlink or website outages and prevents credentials/protocol-specific logic from leaking into the web application.

## Primary hosts

### LEVLAKE-EDGE

Current hardware: Dynabook Portege X40-K.

Current responsibilities:

- LakeAutomate repository/runtime
- local device integration
- Blue Iris
- Tailscale
- RDP
- heavier Windows-native workloads
- possible future Arcade host or VM role

The laptop is particularly valuable as an edge controller because its internal battery provides another resilience layer behind the external UPS.

### lake-core (planned)

A small always-on Pi or mini PC should host boring infrastructure services that should remain independent of LakeAutomate application restarts:

- AdGuard Home
- Mosquitto
- Caddy
- Dockge
- UniFi Network controller
- optional Uptime Kuma

A 1 GB Pi may be usable for a narrow stack, but a 2 GB+ Pi or small x86 mini PC provides more headroom. Hardware should be selected after reuse candidates are inventoried.

## Network topology

Current:

```text
Starlink / CGNAT
       |
Orbi Router + Wi-Fi (10.2.0.1)
       |
TP-Link TL-SG108PE
   |             |
Orbi Sat 1    Orbi Sat 2
(wired)       (wired)
       |
Lake LAN 10.2.0.0/24
       |
LEVLAKE-EDGE 10.2.0.100
```

Planned:

```text
Starlink / CGNAT
       |
UniFi USG
       |
10.2.0.0/24
       |
TP-Link TL-SG108PE
   |       |       |          |
Orbi AP  Sat 1   Sat 2    lake-core
                              |
                         LEVLAKE-EDGE
```

The Orbis should remain the Wi-Fi system but move to AP mode when the USG becomes the router/firewall/DHCP authority.

## Addressing

Current intentional Lake subnet: `10.2.0.0/24`.

Known reservations:

- `10.2.0.1` — Orbi router (future USG gateway)
- `10.2.0.2` — Orbi satellite
- `10.2.0.3` — Orbi satellite
- `10.2.0.15` — ISY994i
- `10.2.0.50` — LG webOS TV
- `10.2.0.51` — LG webOS TV
- `10.2.0.100` — LEVLAKE-EDGE
- DHCP pool currently starts at `10.2.0.120`

The `10.2.0.0/24` network should be preserved through the USG migration unless a concrete conflict is discovered.

## Tailscale

LEVLAKE-EDGE Tailscale address: `100.123.190.89`.

The Lake previously overlapped with the Home `192.168.1.0/24` subnet. A Tailscale subnet route caused Home addresses to win over local Lake addresses, proving the overlap was unsafe. The move to `10.2.0.0/24` resolves that collision.

Do not design LakeAutomate around public inbound port forwarding. Starlink uses CGNAT; Tailscale is the preferred remote-access path.

## MQTT direction

Mosquitto is planned as the local event/state bus. LakeAutomate should publish normalized state, preferably retained for current-value topics.

Examples:

```text
lake/blueiris/health
lake/blueiris/cpu
lake/blueiris/gpu
lake/blueiris/ram
lake/blueiris/storage
lake/blueiris/warnings
lake/blueiris/alerts
lake/edge/health
lake/edge/battery
lake/edge/ups
lake/network/internet
lake/cameras/<camera>/online
lake/cameras/<camera>/last_motion
```

Topic design should favor stable semantic state over application-specific implementation details.

## Recovery philosophy

Lake infrastructure must be recoverable without a person on site.

LEVLAKE-EDGE has passed unattended recovery tests for:

- Windows reboot
- pre-login Ethernet
- pre-login Tailscale
- pre-login RDP
- Blue Iris automatic service startup
- Blue Iris recording before login
- external UPS handoff
- laptop battery handoff
- AC restore
- BIOS Power on by AC
- Blue Iris/Tailscale recovery after cold boot

Wake-on-LAN is also enabled as a secondary future recovery mechanism. A local `lake-core` host could send the magic packet if necessary.

Shelly plugs are planned for selective hard recovery of infrastructure such as Starlink, Orbi/AP equipment, or flaky cameras. Any power-cycle automation must be able to complete the OFF-to-ON cycle locally without depending on the network path being restored midway.
