# Blue Iris on LEVLAKE-EDGE

## Version and licensing

- Blue Iris version: `5.9.4.11 x64`
- Build date: 2024-07-21
- License maintenance through: 2024-07-23
- Automatic updates: **disabled**

This build is intentionally pinned because it is within the perpetual license's maintenance entitlement window. Newer builds should not be installed unless maintenance is renewed or entitlement is otherwise confirmed.

## Service operation

Blue Iris is installed as the Windows service `BlueIris`.

Expected state:

```text
Status: Running
StartType: Automatic
SessionId: 0
```

The service has been verified to start before interactive login and continue recording while Windows remains at the login screen.

## Unattended recovery test results

The following recovery path has been tested successfully:

```text
shutdown / power failure
    -> UPS / laptop battery behavior
    -> power restored
    -> BIOS Power on by AC
    -> Windows cold boot
    -> Ethernet available before login
    -> Tailscale available before login
    -> RDP available before login
    -> Blue Iris service starts in Session 0
    -> recording resumes without interactive login
```

BIOS settings:

- Power on by AC: Enabled
- Wake on LAN: Enabled

## UPS

UPS: APC BN600U1 / Back-UPS NS 600U1 family.

Windows detects both:

- Dynabook internal battery
- APC HID UPS battery

Current Windows battery policy:

- Low battery level: 15%
- Low battery action: Do nothing
- Critical battery level: 8%
- Critical battery action: Shut down
- Reserve battery level: 4%
- Notifications: On

Because Windows battery policy is global across the machine's batteries, the critical action may be triggered by either the UPS or the internal laptop battery. For this unattended controller that is acceptable: either condition means a clean shutdown is preferable.

## Recording policy

Lake recording should be motion/trigger based, **not continuous**.

Current intended camera recording behavior:

- Video: When triggered
- Pre-trigger buffer: 5 seconds
- Trigger ends after approximately 10 seconds without retrigger
- Maximum trigger/alert duration: approximately 60 seconds
- Avoid combining multiple events into long 8-hour BVR clips unless there is a specific reason

Storage allocation is intentionally modest; approximately 50-56 GB is sufficient as a starting point for a small motion-only lake camera set. Actual retention should be adjusted after observing real daily storage consumption.

## Web server

Blue Iris built-in web server:

- Enabled
- Port: `81`
- Lake LAN URL: `http://10.2.0.100:81`
- Tailscale URL: `http://100.123.190.89:81`
- Bind exclusively: Off
- Public Starlink port forwarding: **not required and should not be used**

Starlink is behind CGNAT. Remote access should use Tailscale rather than exposing Blue Iris to the public Internet.

A dedicated Windows firewall rule was added for TCP 81 from Tailscale's `100.64.0.0/10` range, although the built-in Blue Iris Private-profile rules were already permissive.

## Integration account

Blue Iris user: `LevWebUser`.

The account is intentionally restricted and is suitable for LakeAutomate/API use.

Observed login permissions include:

```text
admin=False
changeprofile=False
ptz=False
audio=False
clips=True
clipcreate=False
```

Credentials must not be committed to Git. Store the username/password in environment variables or another local secrets mechanism.

## JSON API

Endpoint:

```text
POST http://10.2.0.100:81/json
```

Authentication flow tested successfully on 5.9.4.11:

1. POST `{"cmd":"login"}`.
2. Blue Iris returns a session challenge with `result=fail` and `reason=missing response`.
3. Compute lowercase MD5 of `userid:session:password`.
4. POST `cmd=login`, the same session, and the MD5 response.
5. Successful response returns `result=success`.

Do not reuse a stale copied session; generate and consume the challenge in one operation.

### Status command

The `status` command has been tested and provides excellent telemetry for LakeAutomate.

Observed fields include:

- `signal`
- `cxns`
- `cpu`
- `gpu`
- `ram`
- `mem`
- `memphys`
- `memload`
- `folders`
- `disks`
- `profile`
- `schedule`
- `uptime`
- `clips`
- `warnings`
- `alerts`

Example observed status:

```text
cpu=5
gpu=4
mem=348.3MB
memphys=15.6GB
memload=41%
uptime=0:05:12:49
clips=Clips: 17 items, 0.64/56.0GB; C: +335.7GB
warnings=0
alerts=3
profile=1
schedule=Default
```

This makes the Blue Iris API the preferred source for DVR telemetry rather than scraping the desktop UI or polling Windows process counters for CPU/GPU/RAM.

## Planned LakeAutomate normalization

LakeAutomate should poll Blue Iris status on a modest interval, initially around 30-60 seconds, and normalize it to stable fields such as:

```json
{
  "healthy": true,
  "cpu_percent": 5,
  "gpu_percent": 4,
  "blueiris_ram_mb": 348.3,
  "system_ram_percent": 41,
  "uptime": "0:05:12:49",
  "clips": 17,
  "storage_used_gb": 0.64,
  "storage_limit_gb": 56.0,
  "disk_free_gb": 335.7,
  "warnings": 0,
  "alerts": 3,
  "profile": 1,
  "schedule": "Default"
}
```

When Mosquitto is available, publish retained current-state topics under `lake/blueiris/...`.
