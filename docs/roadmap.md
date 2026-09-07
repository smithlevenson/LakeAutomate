# Roadmap

## Completed foundation

- [x] Create GitHub repository `smithlevenson/LakeAutomate` and deploy it to `C:\Projects\LakeAutomate` on LEVLAKE-EDGE.
- [x] Establish repeatable lake network baseline capture.
- [x] Move the Lake LAN to unique `10.2.0.0/24` and eliminate the Home/Lake Tailscale collision.
- [x] Confirm Starlink CGNAT and standardize on Tailscale instead of public inbound forwarding.
- [x] Install/license-pin Blue Iris `5.9.4.11`, run it as an automatic Session-0 service, and verify pre-login recording.
- [x] Test Blue Iris JSON authentication/status and implement `scripts/Get-BlueIrisStatus.ps1` normalized telemetry.
- [x] Verify UPS/laptop-battery handoff, BIOS Power on by AC, Wake on LAN, Tailscale/RDP pre-login, and cold recovery.
- [x] Clean up the Lake DHCP reservation plan and move important devices into intentional address blocks.

## 2026-09-07 Home Assistant / remote-control milestone

- [x] Deploy Home Assistant OS 18.2 as a Generation 2 Hyper-V VM on LEVLAKE-EDGE.
- [x] Reserve Home Assistant at `10.2.0.11`.
- [x] Configure Hyper-V automatic HA startup with a 30-second delay and graceful shutdown.
- [x] Pin Home Assistant Core to `2026.8.0` after `2026.9.1` failed startup with a `probatio.BuildPolicy` import error.
- [x] Configure encrypted weekly Home Assistant backups and store the encryption key separately.
- [x] Integrate ISY994i (`10.2.0.15`) into Home Assistant.
- [x] Confirm Home Assistant state reads and physical device control through ISY.
- [x] Advertise `10.2.0.0/24` through LEVLAKE-EDGE as a Tailscale subnet route.
- [x] Enable Windows IPv4 forwarding on Tailscale and `vEthernet (Lake LAN)`.
- [x] Confirm remote Home Assistant access over Tailscale at `10.2.0.11:80`.
- [x] Install Python 3.13 and create a LakeAutomate virtual environment.
- [x] Stand up the initial FastAPI LakeAutomate runtime on port `8780`.
- [x] Prove `/health` remotely over Tailscale.
- [x] Prove LakeAutomate -> Home Assistant entity-state reads.
- [x] Add authenticated constrained Home Assistant light-control support to the repo.
- [x] Add unattended LakeAutomate startup scripts to the repo.

See `docs/homeassistant.md`.

## Current remote-work priorities

### 1. Home Assistant -> LakeAutomate integration

- [ ] Exercise and harden the authenticated LakeAutomate control endpoint.
- [ ] Add reusable Home Assistant state/service helpers rather than ad-hoc device calls.
- [ ] Add health/error normalization for Home Assistant connectivity.
- [ ] Decide which Home Assistant states should become first-class LakeAutomate semantic state.
- [ ] Add tests for the Home Assistant client and API boundary.

### 2. Home Assistant integration expansion

- [ ] Integrate YoLink hub/sensors.
- [ ] Investigate Phyn integration/API viability.
- [ ] Expose useful Blue Iris health/state through Home Assistant only if it adds value beyond the existing direct BI JSON telemetry.
- [ ] Evaluate Roku / LG webOS / DirecTV integration only where it improves LakeAutomate behavior.
- [ ] Add Shelly after physical deployment.

### 3. LakeAutomate service hardening

- [ ] Store `LAKE_HA_TOKEN` and `LAKE_API_KEY` as unattended machine-level secrets without committing them.
- [ ] Install/verify the `LakeAutomate API` startup task on LEVLAKE-EDGE.
- [ ] Reboot-test LakeAutomate API recovery without interactive login.
- [ ] Add a local service/heartbeat log and basic failure diagnostics.
- [ ] Restrict control surfaces to high-level, explicitly supported actions rather than arbitrary Home Assistant service passthrough.

## ISY migration — later, deliberately

The ISY remains the underlying Insteon/device bridge for now. Do not rush the logic migration.

- [ ] Inventory existing ISY programs, scenes, and variables.
- [ ] Classify low-level Insteon/device mechanics vs house logic.
- [ ] Move simple local automations to Home Assistant when confidence is high.
- [ ] Move Levenson-specific cross-system orchestration to LakeAutomate.
- [ ] Disable ISY programs only after their replacement has been proven side-by-side.
- [ ] Reduce dependence on the Java ISY Admin Console before its announced end-of-life.

## MQTT / telemetry

Mosquitto remains the intended local state/event bus, preferably on `lake-core`.

- [ ] Deploy Mosquitto locally.
- [ ] Define retained-state, availability, QoS, and namespace conventions.
- [ ] Publish normalized Blue Iris telemetry.
- [ ] Publish LakeAutomate/Edge heartbeat and host telemetry.
- [ ] Add UPS/battery and Internet/network health telemetry.
- [ ] Add camera online/last-motion/recording state where useful.

Initial semantic namespace remains:

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
lake/edge/health
lake/edge/cpu
lake/edge/ram
lake/edge/battery
lake/edge/ups
lake/network/internet
```

## Device registry

- [ ] Create a first-class device registry rather than scattering addresses through integrations.
- [ ] Separate network, cameras, climate, lighting, entertainment, and utilities.
- [ ] Include identity, room, hostname, IP, MAC, vendor/model, protocol, control/status methods, and notes.
- [ ] Prefer local DNS names after Lake AdGuard is deployed.

## Next physical/infrastructure trip

### lake-core / DNS

- [ ] Select/reuse hardware for `lake-core` at reserved `10.2.0.10`.
- [ ] Deploy AdGuard Home.
- [ ] Add Tailscale split DNS `lake -> 10.2.0.10`.
- [ ] Establish `.lake` names such as `ha.lake`, `edge.lake`, `isy.lake`, and `switch.lake`.
- [ ] Deploy Mosquitto, Caddy, Dockge, and UniFi Network controller as appropriate.
- [ ] Consider Uptime Kuma after the essential stack is stable.

### Network migration

- [ ] Bring the UniFi USG to the Lake.
- [ ] Preserve `10.2.0.0/24`.
- [ ] Configure USG as future `10.2.0.1` gateway/firewall/DHCP authority.
- [ ] Put the current Orbi router into AP mode at `10.2.0.4`; keep existing satellites at `.2` and `.3`.
- [ ] Keep `.5` available for another Orbi if useful.
- [ ] Map TP-Link TL-SG108PE physical ports before VLAN changes.
- [ ] Move suitable devices to IoT VLANs only after integration paths are verified.

### Remote hard recovery

- [ ] Bring Shelly Plug US Gen4 units for selective local-completing power-cycle recovery.
- [ ] Prioritize Starlink, Orbi/AP infrastructure, and flaky cameras/devices.
- [ ] Require OFF -> delay -> ON to complete locally after one command.
- [ ] Treat LEVLAKE-EDGE charger cycling as last-resort recovery; the laptop battery means AC removal alone is not a reboot.

## LevLake integration

- [ ] Define the curated semantic state contract from LakeAutomate to LevLake.
- [ ] Feed family-friendly state rather than raw Home Assistant/device payloads.
- [ ] Define high-level requested actions that LevLake may ask LakeAutomate to perform.
- [ ] Keep credentials and device-specific protocol logic out of LevLake.

## Future automations

- [ ] Arrival / Departure / Occupied / Unoccupied state model.
- [ ] HVAC setback and recovery.
- [ ] Freeze protection.
- [ ] Lighting scenes.
- [ ] Water/Phyn monitoring and alerts.
- [ ] Media/TV integrations.
- [ ] Network outage detection / recovery.
- [ ] Safe infrastructure restart actions.

## Lake Arcade / TV architecture

- [ ] Keep LEVLAKE-EDGE in the office/network role unless a compelling reason emerges.
- [ ] Treat the lake equivalent of `ssl-minipc` as a real interactive/gaming endpoint, not a starved utility box.
- [ ] Decide remote ArcadeVM/Moonlight vs local emulation/gaming roles after latency testing.
- [ ] Prefer wired Ethernet for both host and Moonlight client where possible.
