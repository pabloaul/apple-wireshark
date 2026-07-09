local e =  {} -- init module table

e.type = {
    [0x01] = "Hint",
    [0x02] = "Ratcheting",
    [0x03] = "AES SIV",
    [0x04] = "Ratchet",
    [0xf0] = "Ping",
    [0xff] = "Status",
}

-- bluetoothd -> "NO_KEYS_FOR_PEER"
e.status = {
    [0x00] = "Success",
    [0x01] = "Internal Error",
    [0x02] = "Key Not Found",
    [0x03] = "Invalid Parameters",
    [0x04] = "Pairing Busy",
    [0x05] = "Unsupported Version",
    [0x06] = "Operation Timed Out",
    [0x07] = "Failed Verification",
    [0x08] = "No Keys for Peer",
    [0x09] = "No Resources",
    [0x0A] = "Disconnection",
    [0xFF] = "Invalid",
}

e.key_type = {
    [0x0001] = "magicAccIRK",
    [0x0002] = "?",
    [0x0004] = "magicAccEncKey",
    [0x0008] = "magicAccKey",
    [0x0010] = "magicAccHint",
    [0x0020] = "Nonce",
    [0x0040] = "?",
    [0x0080] = "AES SIV",
    [0x0100] = "magicAccRatchet",
    [0x0200] = "guestAccIRK?",
    [0x0400] = "guestAccEncKey?",
    [0x1000] = "MasterCloudIRK",
    [0x2000] = "MasterCloudAddress",
}

return e
