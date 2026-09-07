# Roadmap

## Immediate

- [ ] Install Git on LEVLAKE-EDGE and connect `C:\Projects\LakeAutomate` to this repository.
- [ ] Preserve/import the existing local network baseline file.
- [ ] Bring the second Wi-Fi camera back online on `10.2.0.0/24`.
- [ ] Reserve the second camera's IP.
- [ ] Confirm motion-only recording and playback for all cameras.
- [ ] Finish Blue Iris remote phone access over Tailscale.
- [ ] Export Blue Iris configuration to a safe location outside the laptop.

## MQTT / telemetry milestone

- [ ] Deploy Mosquitto on the future `lake-core` host or temporary suitable host.
- [ ] Define MQTT namespace and retained-state rules.
- [ ] Implement Blue Iris JSON login/session handling.
- [ ] Poll Blue Iris `status` every 30-60 seconds.
- [ ] Publish normalized retained Blue Iris telemetry.
- [ ] Add camera health/last-motion topics.
- [ ] Add LEVLAKE-EDGE host telemetry.
- [ ] Add UPS/battery telemetry.
- [ ] Add network/Internet health telemetry.

## Core infrastructure

- [ ] Select/reuse hardware for `lake-core`.
- [ ] Deploy AdGuard Home.
- [ ] Establish local DNS naming; prefer names over hard-coded IPs in application code.
- [ ] Deploy Caddy.
- [ ] Deploy Dockge.
- [ ] Deploy UniFi Network controller where appropriate.
- [ ] Consider Uptime Kuma after the essential stack is stable.

## Network migration

- [ ] Bring UniFi USG to the Lake.
- [ ] Verify exact USG model, firmware, and compatible UniFi Network version.
- [ ] Document/export current Orbi configuration.
- [ ] Preserve Lake subnet `10.2.0.0/24`.
- [ ] Configure USG as `10.2.0.1` router/firewall/DHCP authority.
- [ ] Put Orbi system into AP mode.
- [ ] Preserve reservations for infrastructure/controllers.
- [ ] Verify Starlink, DNS, DHCP, Tailscale, Blue Iris, and all fixed devices after cutover.

## Remote recovery

- [ ] Bring Shelly smart plugs to Lake.
- [ ] Prioritize remote recovery for Starlink, Orbi/AP infrastructure, and flaky cameras/devices.
- [ ] Require local/timed OFF->ON behavior so a command cannot strand the network.
- [ ] Avoid indiscriminate remote power cycling of the main switch or critical controller path.
- [ ] Integrate safe recovery actions into LakeAutomate only after local behavior is proven.

## Future capabilities

- [ ] Feed selected LakeAutomate state into LevLake website.
- [ ] Arrival / Departure / Occupied / Unoccupied state model.
- [ ] HVAC and freeze-protection automation.
- [ ] Lighting scenes.
- [ ] Water/Phyn monitoring.
- [ ] Media/TV integrations.
- [ ] Lake Arcade architecture: decide host vs Moonlight client vs local emulation roles after hardware reuse inventory.
