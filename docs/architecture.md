# Architecture

## Purpose

LakeAutomate is the **local control plane** for the lake. It owns device integration, automation, telemetry, local operational state, and recovery logic. LevLake is the user-facing website/application and should consume normalized state or request high-level actions rather than directly controlling devices.

## Primary principle

> **LevLake displays and requests. LakeAutomate observes and controls.**

This separation keeps the property functional during Starlink or website outages and prevents credentials/protocol-specific logic from leaking into the web application.

A second practical rule follows from that principle:

> **Local house functions must not depend on the Internet being available.**

Starlink, LevLake, Tailscale, or a cloud API may be unavailable while local MQTT, device control, and safety automation continue to work.

## Host roles

### LEVLAKE-EDGE

Current hardware: Dynabook Portege X40-K.

Current responsibilities:

- LakeAutomate repository/runtime
- local device integration
- Blue Iris NVR/DVR
- Tailscale
- RDP
- diagnostics and recovery
- heavier Windows-native workloads

Potential future responsibilities:

- Arcade host / VM coordination
- UniFi Network controller if `lake-core` is resource constrained
- other local integrations that benefit from Windows/x86

The laptop is especially valuable as the edge controller because its internal battery provides a second resilience layer behind the external UPS. It should normally remain in the office/network area rather than being relocated to satisfy TV/Arcade needs.

### lake-core (planned)

A separate small always-on host is preferred for boring infrastructure that should remain independent of LakeAutomate application restarts:

- AdGuard Home
- Mosquitto
- Caddy
- Dockge
- UniFi Network controller
- optional Uptime Kuma

Candidate hardware should be chosen from reuse inventory first.

Guidance:

- 1 GB Pi: worth trying for a narrow/light stack
- 2 GB+ Pi: comfortable for basic infrastructure
- small x86 mini PC: preferable if price is close and future services justify it
- UniFi controller can be moved to LEVLAKE-EDGE if needed

### Lake TV / Arcade endpoint (planned)

The lake equivalent of `ssl-minipc` is a separate role from `lake-core` and should not be deliberately starved just to run network services.

Likely responsibilities:

- Moonlight client
- controllers
- HDMI to TV
- local emulation/gaming if streaming is unreliable
- possible primary lake gaming PC

This allows LEVLAKE-EDGE to remain where it is most useful while still supporting a good TV/Arcade experience.

## Current network topology

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

All three Orbi units provide Wi-Fi. Both satellites are physically wired through the TP-Link switch; do not infer a wireless daisy-chain from Orbi UI topology drawings.

## Planned network topology

```text
Starlink / CGNAT
       |
UniFi USG
       |
10.2.0.0/24
       |
TP-Link TL-SG108PE
   |        |        |          |             |
Orbi AP   Sat 1    Sat 2    lake-core   LEVLAKE-EDGE
```

The USG should own routing/firewall/DHCP. The Orbis remain the Wi-Fi system but move to AP mode.

The old USG requires an external UniFi Network controller. That controller may run on `lake-core` or LEVLAKE-EDGE.

## Addressing

Current intentional Lake subnet: `10.2.0.0/24`.

Known reservations:

- `10.2.0.1` — Orbi router today; future USG gateway
- `10.2.0.2` — Orbi satellite
- `10.2.0.3` — Orbi satellite
- `10.2.0.15` — ISY994i
- `10.2.0.50` — LG webOS TV
- `10.2.0.51` — LG webOS TV
- `10.2.0.100` — LEVLAKE-EDGE
- DHCP pool currently begins at `10.2.0.120`

A useful long-term allocation pattern is:

```text
10.2.0.1         gateway
10.2.0.2-.9      network infrastructure
10.2.0.10-.29    controllers / automation
10.2.0.30-.99    fixed smart-home devices
10.2.0.100-.119  servers / edge systems
10.2.0.120+      dynamic DHCP
```

Preserve `10.2.0.0/24` through the USG migration unless a concrete conflict is discovered.

## Historical subnet collision

The Lake previously used `192.168.1.0/24`, overlapping Home. Home also advertised `192.168.1.0/24` into Tailscale via TrueNAS.

On LEVLAKE-EDGE, Windows preferred the Tailscale route over the directly connected Lake route. A traceroute to `192.168.1.1` went first to Home TrueNAS (`100.104.90.47`) and then to the Home UCG Ultra.

That incident established a hard rule: site subnets must be unique. The move to `10.2.0.0/24` resolves the collision.

## Starlink and remote access

Traceroute confirms the current upstream path:

```text
10.2.0.1       local Orbi
100.64.0.1     Starlink CGNAT
172.16.x.x     Starlink internal
public Internet
```

Do not design LakeAutomate around public inbound port forwarding. Tailscale is the preferred remote-access path.

Putting Starlink into bypass mode during the future USG cutover can eliminate unnecessary local routing layers, but it does not remove Starlink CGNAT unless the Starlink plan itself provides public IPv4.

## Device registry direction

LakeAutomate should eventually have a first-class device registry rather than scattering addresses through code.

Suggested categories:

```text
devices/
  network.yaml
  climate.yaml
  lighting.yaml
  entertainment.yaml
  utilities.yaml
  cameras.yaml
```

Useful fields include:

```text
name
id
room
hostname
ip
mac
vendor
model
protocol
control_method
status_method
notes
```

Once AdGuard/local DNS is deployed, application code should prefer hostnames over hard-coded addresses.

## MQTT architecture

Mosquitto should become the local event/state bus.

Current-state topics should generally be **retained** so consumers receive current state immediately after reconnecting.

Initial semantic namespace:

```text
lake/blueiris/health
lake/blueiris/cpu
lake/blueiris/gpu
lake/blueiris/ram
lake/blueiris/storage
lake/blueiris/warnings
lake/blueiris/alerts
lake/blueiris/uptime
lake/cameras/<camera>/online
lake/cameras/<camera>/last_motion
lake/cameras/<camera>/recording
lake/edge/health
lake/edge/cpu
lake/edge/ram
lake/edge/battery
lake/edge/ups
lake/network/internet
```

Topic design should favor stable semantic state over application-specific implementation details.

## Blue Iris integration pattern

Blue Iris remains independently responsible for camera recording. LakeAutomate observes Blue Iris through its JSON interface and exposes normalized health/telemetry.

The first working integration is `scripts/Get-BlueIrisStatus.ps1`, which:

1. requests a fresh Blue Iris login challenge;
2. calculates the documented `MD5(user:session:password)` response;
3. authenticates immediately using that same fresh session;
4. calls `status`;
5. normalizes CPU/GPU/RAM/storage/alerts/profile data to JSON.

This means the Blue Iris API, not desktop scraping or Windows counters, is the preferred canonical source for DVR telemetry.

The next step is to make credentials unattended-safe and publish the normalized result to MQTT every 30-60 seconds.

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

Wake-on-LAN is enabled as a secondary future recovery mechanism. A local `lake-core` host could send the magic packet if needed.

### Remote hard-recovery philosophy

Shelly smart plugs are planned for selective hard recovery of:

- Starlink
- Orbi/AP infrastructure
- flaky cameras/devices

Any power-cycle automation must be able to complete the entire OFF -> delay -> ON sequence locally after receiving one command. Never design a recovery that depends on the network being available to send the ON command after the network has just been powered off.

Avoid indiscriminate remote power cycling of the main switch or LEVLAKE-EDGE unless there is a proven local recovery path and suitable guardrails.

## Future automation model

Likely future LakeAutomate state/actions include:

- Arrival
- Departure
- Occupied
- Unoccupied
- freeze protection
- HVAC setback / recovery
- lighting scenes
- Internet/network outage detection
- water/Phyn monitoring
- TV/media state and control
- camera health and recent motion
- remote-safe infrastructure restart actions

LevLake should consume these as high-level state/actions rather than implementing individual device protocols itself.
