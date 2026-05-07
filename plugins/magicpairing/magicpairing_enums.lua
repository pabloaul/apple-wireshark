local e =  {} -- init module table

e.type = {
    [0x01] = "Hint",
    [0x02] = "Ratcheting",
    [0x03] = "AES SIV",
    [0x04] = "Ratchet",
    [0xf0] = "Ping",
    [0xff] = "Status",
}

e.status = {
    [0] = "Success",
    [1] = "Internal Error",
    [2] = "Key Not Found",
    [3] = "Invalid Parameters",
    [4] = "Pairing Busy",
    [5] = "Unsupported Version",
    [6] = "Operation Timed Out",
    [7] = "Failed Verification",
    [8] = "No Keys for Peer"
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
