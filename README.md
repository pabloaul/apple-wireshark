# AACP Wireshark dissector

This repo contains a Wireshark dissector for the Advanced Accessory Control Profile by Apple.
The protocol is used on various audio accessories (e.g. AirPods) and is responsible for handling configuration (anc, buttons, hearing aid), device/health metrics (battery, heartrate, motion), connectivity via magic keys, possibly updates by encapsulating UARP data and checking device authenticity via certificates.

It can also serve as a (crude) reference for the protocol given that I have not found a more extensive one elsewhere yet.
Most of the information was aquired from static analysis of the bluetoothd binary and a bit of poking around at my own device.

## Installation
- Move the lua plugin into:\
  ``~/.local/lib/wireshark/plugins/`` (Linux/MacOS)\
  ``%APPDATA%/Wireshark/plugins/`` (Windows)\
  and reload with Ctrl + Shift + L

## Usage
The AACP service gets advertised with the L2CAP PSM 0x1001 (4097) and the dissector should automatically attach itself to the related L2CAP channels.

However when the Fast Connect protocol gets used, the channel exchange will happen over the payload in L2CAP echos and the PSM gets stripped which will require you to add the dissector manually to the established channels using ``Decode As...`` until Fast Connect functionality gets implemented.
