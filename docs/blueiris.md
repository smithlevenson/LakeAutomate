# Blue Iris on LEVLAKE-EDGE

## Version and licensing

- Blue Iris version: `5.9.4.11 x64`
- Build date: 2024-07-21
- License maintenance through: 2024-07-23
- Automatic updates: **disabled**

This build is intentionally pinned because it is within the perpetual license maintenance entitlement window. Newer builds should not be installed unless maintenance is renewed or entitlement is otherwise confirmed.

## Service operation

Blue Iris is installed as the Windows service `BlueIris`.

Expected/verified state:

```text
Status: Running
StartType: Automatic
SessionId: 0
```

The service has been verified to start before interactive login and continue recording while Windows remains at the login screen.

A measured reboot test showed Windows boot at `16:14:59` and Blue Iris start at `16:15:21`, roughly 22 seconds after boot, in Session 0.

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

- Power on by AC: Enabled and cold-restore tested
- Wake on LAN: Enabled

The host is considered suitable for remote unattended lake operation.

## UPS

UPS: APC BN600U1 / Back-UPS NS 600U1 family.

Windows USB/HID identification includes:

```text
American Power Conversion USB UPS
HID UPS Battery
Back-UPS NS 600U1 FW:970.a10 .D USB FW:a10
```

Windows detects both the Dynabook internal battery and the APC UPS battery.

Current native Windows battery policy:

- Low battery level: 15%
- Low battery action: Do nothing
- Critical battery level: 8%
- Critical battery action: Shut down
- Reserve battery level: 4%
- Low/critical notifications: On

Windows battery policy is global across the machine's batteries. For this unattended controller, either battery reaching critical is a valid reason to prefer a clean shutdown.

PowerChute is not currently required; native Windows HID UPS handling is the preferred simple design unless testing later proves it inadequate.

## Recording policy

Lake recording should be motion/trigger based, **not continuous**.

Current intended camera behavior:

- Video: When triggered
- Pre-trigger buffer: 5 seconds
- Trigger ends after approximately 10 seconds without retrigger
- Maximum trigger/alert duration: approximately 60 seconds
- ONVIF/video camera events were not required for the tested camera
- `Combine or cut video each` should be OFF when one event per clip is desired

The earlier 8-hour/4-GB combine setting made many triggered events appear as a very long BVR clip. That was a clip-combining behavior, not the desired recording policy.

If genuinely continuous long recording returns, inspect `Motion sensor -> Configure` for constant retriggering from trees, shadows, weather, etc.

## Storage policy

A modest storage allocation is intentional because this is a small motion-only NVR.

Current target:

- approximately 50-56 GB allocated to Blue Iris `New`
- delete/roll oldest recordings when the allocation is full
- do not set aggressive clip-age retention until real daily usage is observed

Example observed status:

```text
0.64 / 56.0 GB used
335+ GB free on C:
17 clips
```

## Web server

Blue Iris built-in web server:

- Enabled
- Port: `81`
- Root: standard Blue Iris `www`
- Adapter display: Lake LAN interface (`10.2.0.100`)
- Bind exclusively: Off
- Lake LAN URL: `http://10.2.0.100:81`
- Tailscale URL: `http://100.123.190.89:81`
- Public Starlink port forwarding: **not required and should not be used**
- NGROK: not required
- stunnel/HTTPS: not required for the current Tailscale-only design

Blue Iris was verified listening on:

```text
:: :81
```

which indicates listening across interfaces.

The built-in Blue Iris firewall rules were already permissive on the Private profile. A dedicated rule was additionally created for TCP 81 from `100.64.0.0/10`:

```text
Blue Iris Web - Tailscale
```

Local access from phone/laptop works. Remote phone access over Tailscale was still an open troubleshooting item at the end of the setup session.

## Integration account

Blue Iris user: `LevWebUser`.

The account is intentionally restricted and suitable for LakeAutomate/API use.

Observed successful login metadata:

```text
system name=LevLake
admin=False
changeprofile=False
ptz=False
audio=False
clips=True
clipcreate=False
version=5.9.4.11
support=7/23/2024
user=LevWebUser
```

Credentials must not be committed to Git.

## JSON API

Endpoint:

```text
POST http://10.2.0.100:81/json
```

### Authentication flow

Tested successfully on 5.9.4.11:

1. POST `{"cmd":"login"}`.
2. Blue Iris returns `result=fail`, a session challenge, and `reason=missing response`.
3. Compute lowercase MD5 of `userid:session:password`.
4. POST `cmd=login`, the same session, and the MD5 response.
5. Successful response returns `result=success`.

Do not reuse a stale copied session. Generate and consume the challenge immediately in the same operation. A stale challenge produced `Invalid session`; a fresh end-to-end flow succeeded.

### Status command

The `status` command is tested and is the canonical DVR telemetry source for LakeAutomate.

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
- `time`
- `tmessage`
- `tzone`

Important discovery: **GPU is exposed by the Blue Iris status API**, so Windows GPU performance counters are not required for the primary Blue Iris telemetry path.

Example raw response data:

```text
signal=1
cxns=1
cpu=5
gpu=4
ram=365322240
mem=348.3MB
memphys=15.6GB
memload=41%
profile=1
schedule=Default
uptime=0:05:12:49
clips=Clips: 17 items, 0.64/56.0GB; C: +335.7GB
warnings=0
alerts=3
```

## Working LakeAutomate client

`scripts/Get-BlueIrisStatus.ps1` is implemented and tested.

It supports:

```text
LAKE_BI_URL
LAKE_BI_USER
LAKE_BI_PASSWORD
```

or securely prompts for the password if none is supplied.

It performs challenge/login/status and emits normalized JSON.

Successful test payload on 2026-09-06:

```json
{
  "healthy": true,
  "cpu_percent": 3,
  "gpu_percent": 1,
  "blueiris_ram_mb": 357.1,
  "system_ram_percent": 44,
  "system_ram_total": "15.6GB",
  "uptime": "0:05:32:55",
  "connections": 0,
  "warnings": 0,
  "alerts": 3,
  "profile": 1,
  "schedule": "Default",
  "clip_count": 17,
  "storage_used_gb": 0.64,
  "storage_limit_gb": 56,
  "disk_free_gb": 335.3,
  "raw_clips_summary": "Clips: 17 items, 0.64/56.0GB; C: +335.3GB",
  "sampled_at": "2026-09-06T22:10:25.4083401-04:00",
  "source": "blueiris-json"
}
```

This replaces the earlier idea of scraping the desktop UI or maintaining a separate Windows process-resource logger for Blue Iris CPU/GPU/RAM.

## Next integration step

1. Store the Blue Iris API credential locally in an unattended-safe way without committing it.
2. Poll status on a modest interval, initially 30-60 seconds.
3. Publish normalized **retained** current state to Mosquitto.
4. Add camera-specific health / last-motion / recording state when useful.
5. Feed only curated, semantic state into LevLake.

Proposed MQTT topics:

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
```

Blue Iris should remain independently responsible for recording even if LakeAutomate or MQTT is unavailable.
