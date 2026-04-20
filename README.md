# Apple Wireshark dissectors
This repo contains Wireshark dissectors for various proprietary bluetooth protocols used by Apple.

They serve as a (very crude) reference for me to help in understanding and come with absolutely no guarantee in version compatibility, correctness or reliability.

Bluetooth captures for related protocols would be much appreciated!

## Protocols
### Advanced Accessory Control Profile (AACP)
The protocol is used on various audio accessories (e.g. AirPods) and is responsible for handling configuration (anc, buttons, hearing aid), device/health metrics (battery, heartrate, motion, crashlogs), managing magic keys, possibly updates by encapsulating UARP data and checking device authenticity via certificates.

### FastConnect
Negotiates L2CAP channels and is also capable of sending some initial protocol commands directly during the connection phase.
Protocols utilizing FastConnect will strip the PSM from SDP, rendering Wireshark unable to assign the dissector to the L2CAP channels by itself.

## Installation
- Move the lua plugin into:\
  ``~/.local/lib/wireshark/plugins/`` (Linux/MacOS)\
  ``%APPDATA%/Wireshark/plugins/`` (Windows)\
  and reload with Ctrl + Shift + L

## Usage
Should just work™ after installing.

Make sure that the initial connection is part of the capture

## Previous work
- [More dissectors with focus on the Apple Watch](https://github.com/seemoo-lab/watchwitch-wireshark)
