# Home Assistant

## Role

Home Assistant is now the normalized device/state layer between LakeAutomate and legacy/local device systems.

Target boundary:

```text
LevLake
  -> LakeAutomate
  -> Home Assistant
  -> ISY / Shelly / YoLink / other device integrations
  -> physical devices
```

LakeAutomate should not add new direct ISY-specific control code unless a concrete Home Assistant limitation requires it.

## Current deployment

Home Assistant OS runs as a Generation 2 Hyper-V VM on `LEVLAKE-EDGE`.

- HAOS: `18.2`
- Home Assistant Core: intentionally pinned to `2026.8.0`
- Supervisor: `2026.08.0`
- VM memory: 4 GB
- VM vCPU: 2
- Hyper-V switch: `Lake LAN` (external, bridged to Intel I219-V Ethernet)
- Lake IP reservation: `10.2.0.11`
- Current HTTP endpoint: `http://10.2.0.11` on port 80
- Hyper-V automatic start: Start, 30-second delay
- Hyper-V automatic stop: ShutDown

Core `2026.9.1` failed during initial deployment with a `probatio.BuildPolicy` import error, so Core was rolled back to `2026.8.0`. Do not upgrade Core until that startup issue has been rechecked.

## Backup

Home Assistant encrypted backups are configured weekly. The encryption key is stored separately from the VM.

## ISY integration

The lake ISY994i at `10.2.0.15` is integrated through Home Assistant's Universal Devices ISY/IoX integration.

Initial import produced roughly 15 devices and 118 entities, including:

- lights/dimmers
- thermostats and thermostat sensors
- garage sensors/relays
- ice-machine switch
- scenes/groups
- query/beep/configuration entities

Physical control from Home Assistant through the ISY has been confirmed.

Example working entities include:

```text
light.main_lamp_1
light.main_lamp_2
light.outside_front_floods
light.outside_side_floods
light.outside_garage_lights
climate.main_main_thermostat_main
climate.downstairs_downstairs_thermostat_main
binary_sensor.outside_left_garage_sensor
binary_sensor.outside_right_garage_sensor
switch.main_ice_machine_1_on_off_module
```

## API

A Home Assistant long-lived access token named `LakeAutomate` is used by LakeAutomate. The token must never be committed to Git.

Environment variables:

```text
LAKE_HA_URL=http://10.2.0.11
LAKE_HA_TOKEN=<secret>
```

The REST API has been proven for both state reads and service calls.

Example proven control path:

```text
LakeAutomate / PowerShell
  -> POST /api/services/light/turn_on
  -> Home Assistant
  -> ISY
  -> physical garage lights
```

## Remote access

`LEVLAKE-EDGE` advertises `10.2.0.0/24` as a Tailscale subnet route. The route is approved in the tailnet, and Windows IPv4 forwarding is enabled on:

```text
Tailscale
vEthernet (Lake LAN)
```

Remote access to Home Assistant at `10.2.0.11:80` has been confirmed from outside the lake LAN over Tailscale.

Do not expose Home Assistant through public Starlink port forwarding.

## Migration direction

The ISY remains the Insteon/device bridge for now. Migration of automation logic should be gradual:

- low-level device/network mechanics may remain on ISY initially;
- straightforward local automations should move to Home Assistant;
- Levenson-specific orchestration and cross-system logic belongs in LakeAutomate;
- LevLake remains presentation/request only.

The strategic goal is to avoid depending on the Java ISY Admin Console for important automation changes as its end-of-life approaches.

## Next integrations

Good remote-work candidates:

- YoLink hub and sensors
- Phyn, if a viable integration/API path exists
- Blue Iris health/telemetry exposure
- Roku / TV / DirecTV only where Home Assistant adds meaningful value
- Shelly after physical deployment
