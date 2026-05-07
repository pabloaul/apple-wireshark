local e =  {} -- init module table

e.state = {
    [0x00] = "Idle",
    [0x01] = "Initial",
    [0x02] = "Echo Sent",
    [0x03] = "Echo Received",
    [0x04] = "Descriptor Sent",
    [0x05] = "Descriptor Received",
    [0x06] = "Config Sent",
    [0x07] = "Config Received",
    [0x08] = "Setup Complete Sent",
    [0x09] = "Setup Complete Received"
}

e.fc_type = {
    [0x01] = "General",
    [0x02] = "Descriptors"
}

e.fc_general_type = {
    [0x01] = "Version",
    [0x02] = "Unknown",
    [0x03] = "Unknown",
    [0x04] = "Unknown"
}

e.fc_common = {
    [0x01] = "L2CAP Config",
    [0x03] = "Version",
    [0x04] = "Status",
}

e.fc_a2dp = {
    [0x10] = "AVDTP Version", -- msg 3,4
    [0x11] = "A2DP Endpoint?", -- msg 3,4
    [0x12] = "Delay Stream Request", -- msg 4
    [0x13] = "L2CAP Media", -- msg 3,4
    [0x14] = "?", -- msg 5
    [0x15] = "?", -- msg 5
}

e.fc_hfp = {
    [0x10] = "?", -- msg 3,4
    [0x11] = "?", -- msg 3
    [0x12] = "?", -- msg 3
    [0x13] = "?", -- msg 3
    [0x14] = "?", -- msg 4
    [0x15] = "?", -- msg 3
    [0x16] = "?", -- msg 4
    [0x17] = "?", -- msg 4
    [0x18] = "?", -- msg 4
    [0x19] = "DLCI Link", -- msg 4
    [0x1A] = "FC XAPL Feature Supported?", -- msg 3
    [0x1B] = "?", -- msg 3
}

e.fc_avrcp = {
    [0x10] = "?", -- msg 3,4
    [0x11] = "L2CAP Browse Channel?" -- not seen
}

e.fc_gatt = {
    [0x10] = "?" -- msg 4
}

e.fc_aacp = {
    [0x10] = "AACP Version??", -- msg 3,4
    [0x12] = "?", -- msg 4
    [0x13] = "Control Commands",
    [0x14] = "Airpods Info",
    [0x16] = "Bud In Ear State",
    [0x17] = "Role State",
    [0x18] = "Battery State",
    [0x19] = "?", -- msg 3 (empty)
    [0x1A] = "Source Capabilities?", -- msg 3
}

e.psm_mapping = {
    [0x0003] = "btrfcomm",
    [0x0017] = "btavctp",
    [0x0019] = "btavdtp",
    [0x001F] = "btatt",
    [0x03E9] = "aacp", -- apple bug?
    [0x1001] = "aacp",
}

e.descriptor_mapping = {
    [0x00000001] = "RFCOMM/HFP",
    [0x00000008] = "AVCTP/AVRCP",
    [0x00000010] = "AVDTP",
    [0x00080000] = "AACP",
    [0x00100000] = "GATT"
}

return e
