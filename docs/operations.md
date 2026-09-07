# LEVLAKE-EDGE Operations and Recovery Baseline

## Purpose

LEVLAKE-EDGE is intended to remain safely operable and recoverable when nobody is physically at the lake. The goal is not theoretical redundancy; it is to prove the actual failure/recovery paths before relying on them from roughly ninety miles away.

## Host

- Hostname: `LEVLAKE-EDGE`
- Hardware: Dynabook Portege X40-K
- LAN: `10.2.0.100`
- Tailscale: `100.123.190.89`
- Primary Ethernet: Intel I219-V, 1 Gbps
- Ethernet network profile: Private
- RDP: TCP 3389

## Service startup baseline

### Blue Iris

Windows service:

```text
Name: BlueIris
StartType: Automatic
SessionId: 0
```

Measured reboot test:

```text
Windows boot:   16:14:59
Blue Iris start:16:15:21
```

Blue Iris therefore started about 22 seconds after boot and did not require an interactive user login.

Actual recording was verified during the pre-login period.

### Tailscale

Windows service:

```text
Name: Tailscale
StartMode: Auto
StartName: LocalSystem
SessionId: 0
```

Measured reboot test:

```text
Windows boot:    16:14:59
tailscaled start:16:15:21
```

A later reboot test confirmed both of these while LEVLAKE-EDGE remained at the Windows login screen:

```text
tailscale ping levlake-edge       PASS
Test-NetConnection 10.2.0.100:3389 PASS
```

No login is required for remote Tailscale or RDP recovery.

## BIOS / firmware recovery settings

- Power on by AC: Enabled
- Wake on LAN: Enabled

`Power on by AC` has been physically tested from a complete shutdown:

```text
machine shut down
-> AC absent
-> AC restored
-> Dynabook powered itself on
```

This is the primary long-outage recovery path.

Wake on LAN is a secondary path. It becomes more useful once a separate always-on `lake-core` host exists locally to send the magic packet.

## Power architecture

The Dynabook has two battery layers:

```text
utility AC
   -> APC BN600U1 external UPS
      -> Dynabook charger
         -> Dynabook internal battery
```

Both external UPS handoff and laptop-battery handoff have been tested successfully while services remained alive.

## UPS

UPS:

```text
APC BN600U1
Back-UPS NS 600U1 FW:970.a10 .D USB FW:a10
```

Windows USB/HID discovery:

```text
American Power Conversion USB UPS
HID UPS Battery
```

Windows also sees the Dynabook internal battery separately.

### Native Windows battery policy

Active power plan: `dynabook standard`.

Current settings:

```text
Low battery level:      15%
Low battery action:     Do nothing
Low notification:       On
Critical battery level: 8%
Critical action:        Shut down
Critical notification:  On
Reserve battery level:  4%
```

The attempted `BATLEVELRESERVE` alias commands were rejected by this system; the existing 4% reserve is acceptable because it is below the 8% shutdown threshold.

Windows battery policy applies globally to the multi-battery system. Either UPS or laptop battery reaching critical may trigger shutdown. For this unattended host, that is acceptable.

PowerChute is not currently installed/required. Prefer the native HID path unless later testing shows a concrete deficiency.

## Tested end-to-end recovery chain

The following has passed in practice:

```text
Blue Iris recording
    -> Windows service
    -> Windows reboot
    -> service startup before login
    -> Ethernet before login
    -> Tailscale before login
    -> RDP before login
    -> external UPS handoff
    -> internal laptop battery handoff
    -> clean shutdown / machine off
    -> AC restored
    -> BIOS Power on by AC
    -> Windows cold boot
    -> no interactive login
    -> Tailscale restored
    -> Blue Iris restored
```

This is the current definition of **remote-safe / ninety-miles-away safe** for LEVLAKE-EDGE.

## Power-management principles

For server/appliance duty:

- do not allow routine sleep while plugged in
- lid-close behavior should not suspend the host if it will be operated closed
- preserve Smart Charging if desired for long-term battery health; it does not conflict with the server role
- prefer clean Windows reboot/shutdown over hard power interruption
- use charger/plug power cycling only as a last-resort recovery tool

## Shelly remote recovery plan

Bring several local-control smart plugs for selected equipment.

Priority candidates:

1. Starlink
2. Orbi/AP infrastructure
3. flaky Wi-Fi cameras/devices

Potential later candidates:

- TV/media equipment
- LEVLAKE-EDGE charger as a carefully guarded last resort

Avoid casually cycling the main switch because doing so can remove the control path required to restore it.

### Mandatory reboot behavior

A remote recovery plug must be capable of executing this entire sequence locally after one command:

```text
OFF
wait N seconds
ON
```

Do not implement a two-command design where the first command kills Internet/network connectivity and a later remote `ON` command is required.

LakeAutomate should eventually expose high-level guarded recovery actions rather than raw plug controls.

## Blue Iris remote access

LAN access has been verified at:

```text
http://10.2.0.100:81
```

Remote access should use Tailscale:

```text
http://100.123.190.89:81
```

Do not expose Blue Iris with public Starlink port forwarding.

At the end of the setup session, remote phone access over Tailscale still required follow-up even though Blue Iris was listening on all interfaces and the Windows firewall configuration was permissive.

## Operational follow-up

Before the next long unattended period, useful follow-up items are:

- restore and reserve the second Wi-Fi camera
- verify motion recording/playback for each camera
- finish Blue Iris phone-over-Tailscale access
- export Blue Iris configuration off-host
- establish unattended-safe Blue Iris API credentials
- deploy MQTT heartbeat/telemetry
- add UPS, battery, host, and network health telemetry
- deploy Shelly recovery plugs and test each power-cycle path locally before relying on it remotely
