local e =  {} -- init module table

e.type = {
    [0x01] = "Advertise Remote Services",
    [0x02] = "Response Remote Services ",
    [0x03] = "Service Channel Created",
    [0x04] = "Service Channel Accepted",
    [0x05] = "Service Added",
    [0x06] = "Service Removed",
    [0x07] = "Service Removal Acknowledged",
    [0x08] = "Error Response",
    [0x09] = "Version Info",
    [0x70] = "Request Time Data", -- "TimeSyncCorrection"
    [0x71] = "Time Data type 1",
    [0x72] = "Time Data type 2",
    [0x90] = "Device Identification",
    [0x91] = "CoreLocation Durian"
}

e.did_chipset = {
    [0x000e] = "A11 Bionic",
    [0x000f] = "A11 Bionic",
    [0x0012] = "H2",
    [0x0013] = "A12 Bionic",
    [0x0014] = "A14 Bionic",
    [0x0016] = "A16 Bionic",
    [0x07d1] = "W2?",
    [0x07d2] = "W3",
}

return e
