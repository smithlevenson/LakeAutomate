# LakeAutomate

LakeAutomate is the local automation and telemetry layer for the Levenson Lake property.

Its primary runtime host is **LEVLAKE-EDGE**, a Dynabook Portege X40-K that remains on-site and is designed to operate unattended. LakeAutomate owns local device integrations, automation logic, telemetry, health monitoring, and the API/MQTT-facing state that the LevLake website can consume.

## Core architecture rule

> **LevLake displays and requests. LakeAutomate observes and controls.**

The public/family-facing LevLake website should not contain device-specific logic or credentials. LakeAutomate should normalize local state and actions and expose only the information and controls the website needs.

## Current site baseline

- Lake LAN: `10.2.0.0/24`
- Current gateway/router: Orbi at `10.2.0.1`
- LEVLAKE-EDGE: reserved at `10.2.0.100`
- Tailscale: `100.123.190.89`
- Internet: Starlink behind CGNAT
- Orbi system: one router/AP plus two wired-backhaul satellites
- Core switch: TP-Link TL-SG108PE
- Planned router migration: UniFi USG with Orbis in AP mode
- Planned infrastructure host: `lake-core` Pi or mini PC

## Current LEVLAKE-EDGE roles

- LakeAutomate development/runtime host
- Tailscale remote-access endpoint
- RDP remote administration
- Blue Iris NVR/DVR
- Potential future Arcade host / VM coordination

## Blue Iris

Blue Iris 5.9.4.11 is installed and pinned because the perpetual license maintenance period ends 2024-07-23. Automatic updates should remain disabled unless the license is renewed.

Blue Iris runs as an automatic Windows service in Session 0 and has been tested through reboot, pre-login operation, UPS/battery handoff, shutdown, AC restore, BIOS power-on-by-AC, and unattended service recovery.

The Blue Iris JSON API is available locally and exposes useful telemetry including CPU, GPU, RAM, storage, uptime, alerts, warnings, active profile, and schedule. See `docs/blueiris.md`.

## Planned infrastructure

The next infrastructure layer is MQTT and local DNS/services, likely split between LEVLAKE-EDGE and a future `lake-core` host:

- Mosquitto
- AdGuard Home
- Caddy
- Dockge
- UniFi Network controller
- optional Uptime Kuma

LakeAutomate should publish normalized retained MQTT state for LevLake and future local consumers.

## Repository layout

```text
LakeAutomate/
├── README.md
├── docs/
│   ├── architecture.md
│   ├── blueiris.md
│   ├── network/
│   │   └── README.md
│   └── roadmap.md
└── .gitignore
```

## Near-term priorities

1. Finish lake camera inventory and bring the second Wi-Fi camera back online.
2. Finish Blue Iris-over-Tailscale remote phone access.
3. Add Mosquitto and define retained MQTT topic conventions.
4. Build the first LakeAutomate Blue Iris integration using the JSON API.
5. Add host/UPS/network telemetry.
6. Add Shelly-based remote power-cycle recovery for selected infrastructure.
7. Migrate routing from Orbi to UniFi USG while preserving `10.2.0.0/24`.
