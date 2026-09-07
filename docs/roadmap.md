# Roadmap

## Completed foundation

- [x] Create GitHub repository `smithlevenson/LakeAutomate`.
- [x] Install Git on LEVLAKE-EDGE and connect `C:\Projects\LakeAutomate` to `origin/main`.
- [x] Establish repeatable lake network baseline capture script.
- [x] Move Lake LAN to unique `10.2.0.0/24` subnet and eliminate Home/Lake Tailscale subnet collision.
- [x] Reserve LEVLAKE-EDGE at `10.2.0.100`.
- [x] Set LEVLAKE-EDGE Ethernet profile to Private.
- [x] Confirm Starlink CGNAT and choose Tailscale instead of public inbound forwarding.
- [x] Install and license-pin Blue Iris `5.9.4.11`.
- [x] Run Blue Iris as an automatic Session-0 Windows service.
- [x] Verify Blue Iris records before login.
- [x] Verify Tailscale and RDP return before login.
- [x] Verify UPS handoff and laptop battery handoff.
- [x] Enable and test BIOS Power on by AC.
- [x] Enable Wake on LAN.
- [x] Verify cold power restore -> Windows -> Tailscale -> Blue Iris without login.
- [x] Configure native Windows APC UPS battery policy: 15% low warning, 8% critical shutdown, 4% reserve.
- [x] Configure Blue Iris motion/trigger recording direction and modest ~50-56 GB storage allocation.
- [x] Test Blue Iris JSON authentication and `status` API on 5.9.4.11.
- [x] Confirm Blue Iris API exposes CPU, GPU, RAM, storage, uptime, alerts, warnings, profile, and schedule.
- [x] Implement and test `scripts/Get-BlueIrisStatus.ps1` normalized JSON output.

## Immediate trip closeout

- [ ] Bring the second Wi-Fi camera back online on `10.2.0.0/24`.
- [ ] Reserve the second camera IP.
- [ ] Confirm motion-only recording and playback for all intended cameras.
- [ ] Finish remote Blue Iris phone access over Tailscale.
- [ ] Export Blue Iris configuration to a safe location outside LEVLAKE-EDGE.
- [ ] Reconfirm laptop sleep/lid behavior is suitable for unattended appliance duty.

## MQTT / telemetry milestone

This is the next major LakeAutomate milestone.

- [ ] Select temporary/permanent Mosquitto host.
- [ ] Deploy Mosquitto locally.
- [ ] Define MQTT namespace, QoS expectations, retained-state rules, and availability conventions.
- [ ] Make Blue Iris credentials unattended-safe without storing secrets in Git.
- [ ] Turn `Get-BlueIrisStatus.ps1` logic into a continuously running or scheduled LakeAutomate publisher.
- [ ] Poll Blue Iris status approximately every 30-60 seconds.
- [ ] Publish normalized retained Blue Iris telemetry.
- [ ] Publish a LakeAutomate/Edge heartbeat/availability topic.
- [ ] Add camera online/offline state.
- [ ] Add camera last-motion / recording state where practical.
- [ ] Add LEVLAKE-EDGE CPU/RAM/system telemetry.
- [ ] Add APC UPS and laptop battery telemetry.
- [ ] Add Internet/network health telemetry.

Initial topic direction:

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

Current-value topics should normally be retained.

## Device registry

- [ ] Create first-class device registry rather than hard-coding addresses in integrations.
- [ ] Separate categories such as network, cameras, climate, lighting, entertainment, and utilities.
- [ ] Include identity, room, hostname, IP, MAC, vendor/model, protocol, control/status methods, and notes.
- [ ] Prefer local DNS names over IP literals after AdGuard is deployed.

Initial likely integrations:

- [ ] ISY994i
- [ ] Phyn water device
- [ ] Roku
- [ ] LG webOS TVs
- [ ] cameras / Blue Iris camera health
- [ ] Shelly recovery plugs
- [ ] network infrastructure health

## Core infrastructure

- [ ] Inventory old/reusable PCs, laptops, thin clients, Pi hardware, and mini PCs before purchasing anything.
- [ ] Select/reuse hardware for `lake-core`.
- [ ] Deploy AdGuard Home.
- [ ] Establish local DNS naming and rewrites.
- [ ] Deploy Caddy.
- [ ] Deploy Dockge.
- [ ] Deploy UniFi Network controller where appropriate.
- [ ] Consider Uptime Kuma after the essential stack is stable.

`lake-core` is intended to be boring always-on infrastructure. The separate Lake TV/Arcade machine should be sized for Moonlight/local gaming rather than being sacrificed to infrastructure duty.

## Network migration

- [ ] Bring UniFi USG to the Lake.
- [ ] Verify exact USG model, firmware, and compatible UniFi Network version.
- [ ] Document/export current Orbi configuration.
- [ ] Preserve Lake subnet `10.2.0.0/24`.
- [ ] Configure USG as `10.2.0.1` router/firewall/DHCP authority.
- [ ] Put Orbi system into AP mode.
- [ ] Preserve reservations for infrastructure/controllers.
- [ ] Verify Starlink, DNS, DHCP, Tailscale, Blue Iris, and all fixed devices after cutover.
- [ ] Consider Starlink bypass mode as part of the cutover; do not expect it to remove Starlink CGNAT.

## Remote recovery

- [ ] Bring 3-4 Shelly Plug US Gen4 units or equivalent local-control plugs to Lake.
- [ ] Prioritize recovery for Starlink, Orbi/AP infrastructure, and flaky cameras/devices.
- [ ] Require local/timed OFF -> delay -> ON behavior so a recovery command cannot strand the network.
- [ ] Avoid indiscriminate remote power cycling of the main switch.
- [ ] Treat LEVLAKE-EDGE charger cycling as last-resort recovery, not the normal reboot path.
- [ ] Add safe high-level LakeAutomate recovery actions only after each local power-cycle behavior is proven.

Possible future actions:

```text
Restart Starlink
Restart Orbi Wi-Fi
Restart Camera 1
Restart Camera 2
Power-cycle TV
```

## LevLake integration

- [ ] Define the data boundary between LakeAutomate and LevLake.
- [ ] Feed curated semantic state into LevLake rather than raw device payloads.
- [ ] Create family-friendly lake health cards, e.g. camera health, Internet, UPS, temperature, occupancy.
- [ ] Define high-level requested actions that LevLake may ask LakeAutomate to perform.

Example future camera card:

```text
Cameras — Healthy
2/2 online · DVR 5% CPU · 4% GPU · 348 MB · 1% storage
```

## Future automations

- [ ] Arrival / Departure / Occupied / Unoccupied state model.
- [ ] HVAC setback and recovery.
- [ ] Freeze-protection automation.
- [ ] Lighting scenes.
- [ ] Water/Phyn monitoring and alerts.
- [ ] Media/TV integrations.
- [ ] Network outage detection / recovery.
- [ ] Safe infrastructure restart actions.

## Lake Arcade / TV architecture

- [ ] Inventory reusable hardware first.
- [ ] Keep LEVLAKE-EDGE in the office/network location unless there is a compelling reason to move it.
- [ ] Decide Arcade host vs Moonlight client vs local gaming/emulation roles.
- [ ] Treat the lake equivalent of `ssl-minipc` as a real interactive/gaming endpoint, not a starved utility box.
- [ ] Prefer wired Ethernet for both Arcade host and Moonlight client where possible.
