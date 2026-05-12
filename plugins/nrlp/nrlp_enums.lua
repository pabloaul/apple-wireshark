local e =  {} -- init module table

e.type = {
    [0x00] = "Pad0",
    [0x01] = "PadN",
    [0x02] = "UncompressedIP",
    [0x03] = "Encapsulated6LoWPAN",
    [0x04] = "IKEv2PointToPoint",
    [0x05] = "ControlMessage",

    [0x64] = "KnownIPv6Hdr_ESP",
    [0x65] = "KnownIPv6Hdr_ESP_ECT0",
    [0x66] = "KnownIPv6Hdr_TCP",
    [0x67] = "KnownIPv6Hdr_TCP_ECT0",
    [0x68] = "KnownIPv6Hdr_ESP_ClassC",
    [0x69] = "KnownIPv6Hdr_ESP_ClassC_ECT0",
}

return e
