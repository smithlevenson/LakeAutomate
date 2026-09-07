# LakeAutomate

LakeAutomate is the local automation, telemetry, and recovery layer for the Levenson Lake property.

Its primary runtime host is **LEVLAKE-EDGE**, a Dynabook Portege X40-K that remains on-site and is designed to operate unattended. LakeAutomate owns local device integrations, automation logic, normalized telemetry, health monitoring, and the local API/MQTT-facing state that the LevLake website can consume.

## Core architecture rule

> **LevLake displays and requests. LakeAutomate observes and controls.**

The family-facing LevLake website should not contain device-specific credentials, protocol logic, or direct control code. LakeAutomate should translate local devices into stable semantic state and high-level actions.

This also means lake automation must continue working when Starlink, Tailscale, or the public website is unavailable.

## Current site baseline

- Lake LAN: `10.2.0.0/24`
- Current gateway/router/DHCP/DNS: Orbi at `10.2.0.1`
- DHCP pool: `10.2.0.120-10.2.0.254`
- LEVLAKE-EDGE: reserved at `10.2.0.100`
- LEVLAKE-EDGE Ethernet MAC: `68:45:F1:21:14:4E`
- Tailscale: `100.123.190.89`
- Internet: Starlink behind CGNAT
- Orbi system: one router/AP plus two wired-backhaul satellites
- Core switch: TP-Link TL-SG108PE
- Planned router migration: UniFi USG with Orbis in AP mode
- Planned infrastructure host: `lake-core`, using reused hardware, a Pi, or a small x86 PC depending on what is available

Known fixed/reserved devices include the two Orbi satellites (`10.2.0.2`, `.3`), ISY994i (`10.2.0.15`), two LG webOS TVs (`10.2.0.50`, `.51`), and LEVLAKE-EDGE (`10.2.0.100`).

## LEVLAKE-EDGE roles

Current:

- LakeAutomate repository/runtime host
- Tailscale remote-access endpoint
- RDP remote administration
- Blue Iris NVR/DVR
- local recovery/diagnostic host

Possible future:

- heavier Windows-native integrations
- Arcade host / VM coordination
- UniFi Network controller if the eventual `lake-core` host is too constrained

The laptop should generally remain in the office/network area rather than being moved to the Arcade/TV location. Its built-in battery is part of the resilience architecture.

## Current working integrations

### Network baseline

`scripts/Get-LakeNetworkBaseline.ps1` creates repeatable raw network captures under `docs/network/baseline-*.txt`. Raw baselines are intentionally gitignored; durable facts belong in `docs/network/README.md`.

### Blue Iris telemetry

`scripts/Get-BlueIrisStatus.ps1` is the first working LakeAutomate device integration.

It performs the tested Blue Iris JSON challenge/login flow, calls `status`, parses the result, and emits normalized JSON including:

- health
- CPU %
- GPU %
- Blue Iris RAM
- system RAM usage
- uptime
- connections
- warnings
- alerts
- active profile/schedule
- clip count
- storage used/limit
- disk free

A live test on 2026-09-06 returned a healthy payload with approximately 3% CPU, 1% GPU, 357 MB Blue Iris RAM, 44% system RAM use, 17 clips, and 0 warnings.

Credentials are not stored in Git. The script currently supports `LAKE_BI_URL`, `LAKE_BI_USER`, and `LAKE_BI_PASSWORD`, and otherwise prompts securely for the password. The next step is unattended-safe local credential storage.

## Blue Iris / DVR baseline

- Blue Iris: `5.9.4.11 x64`, intentionally pinned
- Automatic updates: disabled
- Runs as automatic Windows service in Session 0
- Motion/trigger recording, not continuous
- Pre-trigger buffer: 5 seconds
- Trigger ends after about 10 seconds without retrigger
- Maximum trigger/alert duration: about 60 seconds
- Storage target: about 50-56 GB initially
- Web server: port `81`
- LAN access: `http://10.2.0.100:81`
- Tailscale access target: `http://100.123.190.89:81`
- Public Starlink port forwarding: prohibited/unneeded
- API account: restricted `LevWebUser`

See `docs/blueiris.md`.

## Unattended recovery baseline

LEVLAKE-EDGE has been tested through the full recovery chain and is considered suitable for remote unattended operation:

```text
power loss / shutdown
    -> external APC UPS / laptop battery
    -> clean Windows shutdown policy if battery reaches critical
    -> utility power returns
    -> BIOS Power on by AC
    -> Windows cold boot
    -> Ethernet before login
    -> Tailscale before login
    -> RDP before login
    -> Blue Iris service in Session 0
    -> recording available without interactive login
```

BIOS:

- Power on by AC: enabled and physically tested
- Wake on LAN: enabled

UPS:

- APC BN600U1 / Back-UPS NS 600U1
- native Windows HID UPS support
- low battery: 15%, warning only
- critical battery: 8%, shut down
- reserve: 4%

See `docs/operations.md`.

## Planned infrastructure

The next infrastructure layer is local MQTT and DNS/services, preferably independent of application restarts:

- Mosquitto
- AdGuard Home
- Caddy
- Dockge
- UniFi Network controller
- optional Uptime Kuma

`lake-core` should be a boring always-on host if suitable reused hardware is available. A 1 GB Pi can be tried for a narrow stack, but 2 GB+ or x86 gives more comfortable headroom, especially with UniFi. The controller can move to LEVLAKE-EDGE without changing the overall architecture.

The lake equivalent of `ssl-minipc` should not be undersized merely to host infrastructure. Its likely higher-value role is a TV-side Moonlight/local-gaming/emulation endpoint and possibly the lake gaming PC. Infrastructure can run elsewhere.

## MQTT direction

Mosquitto should become the local state/event bus. Current-state telemetry should generally be **retained**, so LevLake or another consumer immediately receives current state after reconnecting.

Initial topics are expected to include:

```text
lake/blueiris/health
lake/blueiris/cpu
lake/blueiris/gpu
lake/blueiris/ram
lake/blueiris/storage
lake/blueiris/alerts
lake/blueiris/warnings
lake/blueiris/uptime
lake/cameras/<camera>/online
lake/cameras/<camera>/last_motion
lake/cameras/<camera>/recording
lake/edge/cpu
lake/edge/ram
lake/edge/battery
lake/edge/ups
lake/network/internet
```

Topic names should express semantic lake state, not implementation details.

## Repository / Edge setup

Git is installed on LEVLAKE-EDGE. The local repo is:

```text
C:\Projects\LakeAutomate
```

and tracks:

```text
https://github.com/smithlevenson/LakeAutomate.git
main -> origin/main
```

PowerShell execution policy for the current user was changed to `RemoteSigned` so local LakeAutomate scripts can run normally.

## Near-term priorities

1. Make Blue Iris credentials unattended-safe without committing secrets.
2. Deploy Mosquitto and define retained MQTT conventions.
3. Turn the working Blue Iris status client into the first continuous LakeAutomate publisher/heartbeat.
4. Bring the second Wi-Fi camera back online, reserve it, and confirm motion recording/playback.
5. Finish remote Blue Iris phone access over Tailscale.
6. Export Blue Iris configuration somewhere outside LEVLAKE-EDGE.
7. Add Edge host, UPS/battery, and Internet/network telemetry.
8. Bring Shelly plugs for safe local timed power-cycle recovery.
9. Inventory reuse hardware before buying `lake-core` or Arcade hardware.
10. Later migrate routing to UniFi USG while preserving `10.2.0.0/24`.
