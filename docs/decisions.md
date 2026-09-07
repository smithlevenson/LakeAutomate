# Architecture Decisions

This file records important LakeAutomate decisions so future work does not reopen settled questions without a concrete reason.

## 1. Separate LevLake from LakeAutomate

**Decision:** LevLake is the family-facing website/application. LakeAutomate is the local control/telemetry plane.

Rule:

> **LevLake displays and requests. LakeAutomate observes and controls.**

LevLake should not own device credentials, direct device protocols, or safety-critical local logic.

## 2. Keep automation local

**Decision:** Local automation must continue if Starlink or the website is unavailable.

Cloud/public services may consume state or request actions, but they are not the execution substrate for the house.

## 3. Preserve Lake subnet `10.2.0.0/24`

**Decision:** Keep `10.2.0.0/24` through the planned router migration.

Reason: the previous Lake `192.168.1.0/24` network collided with Home and was demonstrably misrouted through Tailscale. `10.2.0.0/24` is now clean, intentional, and already reflected in reservations.

## 4. Use Tailscale, not public port forwarding

**Decision:** Remote management and local service access should use Tailscale.

Reason: Starlink is behind CGNAT and there is no benefit to exposing local services publicly.

## 5. Future router is UniFi USG; Orbis become APs

**Decision:** When the old USG is brought to the Lake, it should become router/firewall/DHCP authority while the three Orbis remain the Wi-Fi system in AP mode.

The existing TL-SG108PE remains the wired distribution/backhaul switch.

## 6. External UniFi controller may live on lake-core or Edge

**Decision:** The legacy USG requires an external controller. Prefer `lake-core` if practical, but moving UniFi Network to LEVLAKE-EDGE is an acceptable escape hatch.

Do not force oversized `lake-core` hardware solely to satisfy the controller.

## 7. Keep LEVLAKE-EDGE in the office/network role

**Decision:** Do not move LEVLAKE-EDGE beside a TV merely to satisfy Arcade/Moonlight needs unless a later design proves that necessary.

The Dynabook's best qualities for LakeAutomate are its wired network location, battery, Windows compatibility, remote administration, and recovery behavior.

## 8. Separate the TV/Arcade endpoint role

**Decision:** The lake equivalent of `ssl-minipc` is an interactive TV/gaming endpoint, not merely a network utility host.

It should be sized for Moonlight, controllers, local emulation, and possibly local gaming. Infrastructure can run on a Pi, reused PC, or other host.

## 9. Reuse hardware before buying new hardware

**Decision:** Inventory old PCs/laptops/thin clients/Pis before purchasing `lake-core` or Arcade hardware.

A 1 GB Pi is acceptable to experiment with for a light infrastructure stack; 2 GB+ or x86 provides more comfortable headroom. A Pi 5 8 GB at high retail pricing is not automatically better value than a small x86 PC.

## 10. Blue Iris is the selected NVR

**Decision:** Use Blue Iris rather than Agent DVR for the current Lake camera appliance.

Reason: both could operate as standalone services, and Blue Iris provided a mature Windows service path that fit LEVLAKE-EDGE.

Blue Iris is pinned to `5.9.4.11` because that build predates the existing license's maintenance expiration.

## 11. Blue Iris records motion/events, not continuously

**Decision:** Lake camera recording should be trigger-based, not continuous.

Initial tuning: 5-second pre-trigger, roughly 10-second no-retrigger end, roughly 60-second max trigger/alert duration, and no unnecessary 8-hour clip combining.

## 12. Blue Iris JSON is the canonical DVR telemetry source

**Decision:** Use the Blue Iris JSON `status` interface for DVR telemetry instead of scraping the UI or maintaining separate Windows performance counters for Blue Iris CPU/GPU/RAM.

Reason: tested Blue Iris 5.9.4.11 returns CPU, GPU, RAM, storage, uptime, alerts, warnings, profile, and schedule directly.

## 13. MQTT is the local state/event bus

**Decision:** Deploy Mosquitto and use MQTT as the primary local telemetry/event fabric.

Current-state topics should generally be retained. LevLake should consume normalized semantic state, not raw device payloads.

## 14. Credentials stay outside Git

**Decision:** Device/API credentials must not be committed.

Blue Iris and Home Assistant integrations follow this rule. Unattended services should load secrets from host-local protected configuration or environment, not source files.

## 15. Native Windows UPS handling is sufficient for now

**Decision:** Use the APC BN600U1 through Windows' native HID battery stack unless a concrete deficiency is discovered.

Current policy is 15% low warning, 8% critical shutdown, 4% reserve.

## 16. Recovery must work without a person present

**Decision:** New critical services are not considered complete until their startup/recovery path is proven without an interactive login where appropriate.

LEVLAKE-EDGE has already passed reboot, pre-login networking, Blue Iris, UPS/laptop-battery handoff, AC restore, BIOS power-on-by-AC, and Home Assistant VM auto-start tests.

## 17. Hard power cycles require local completion

**Decision:** Shelly-based restart actions must execute OFF -> delay -> ON locally after one remote command.

Never design a power-cycle operation that kills the very network path required to send the ON command.

## 18. Prefer names over addresses once local DNS exists

**Decision:** IP reservations provide stability now, but application code should eventually use local DNS names managed through AdGuard/rewrite infrastructure rather than hard-coded addresses.

## 19. Home Assistant is the normalized device/state layer

**Decision:** Home Assistant sits between LakeAutomate and device-specific integrations when a solid HA integration exists.

Target boundary:

```text
LevLake -> LakeAutomate -> Home Assistant -> device bridge/integration -> physical device
```

Reason: Home Assistant already normalizes device state, service calls, discovery, and protocol-specific integrations. LakeAutomate should not recreate that ecosystem.

## 20. ISY becomes a legacy device bridge, not the long-term logic home

**Decision:** Keep the ISY994i in service as the Insteon/device bridge while gradually migrating automation logic away from the Java Admin Console.

Simple local automations can move to Home Assistant; Levenson-specific cross-system orchestration belongs in LakeAutomate. Migration should be deliberate and side-by-side, not a big-bang rewrite.

## 21. LEVLAKE-EDGE is the current Lake Tailscale subnet router

**Decision:** LEVLAKE-EDGE advertises `10.2.0.0/24` into Tailscale and forwards traffic between Tailscale and `vEthernet (Lake LAN)`.

This provides private remote access to Lake services such as Home Assistant without public Starlink port forwarding.

## 22. LakeAutomate exposes a small authenticated API, not raw Home Assistant passthrough

**Decision:** LakeAutomate may expose health/state and explicitly supported high-level control endpoints over Tailscale. Mutating/control endpoints require LakeAutomate authentication.

Do not expose arbitrary Home Assistant service passthrough to LevLake. The public-facing application should request curated actions with bounded behavior.

## 23. Home Assistant Core is temporarily pinned

**Decision:** Keep Home Assistant Core on `2026.8.0` until the observed `2026.9.1` startup failure involving `probatio.BuildPolicy` has been rechecked/resolved.

HAOS and Supervisor may remain current as long as compatibility is verified.

## 24. Reserve `lake-core` at `10.2.0.10` and use `.lake` split DNS later

**Decision:** `10.2.0.10` is reserved for the future `lake-core` infrastructure host. When Lake AdGuard exists, Tailscale split DNS should route the `lake` namespace to it.

Expected model:

```text
home -> Home AdGuard at 192.168.1.12
lake -> Lake AdGuard at 10.2.0.10
```
