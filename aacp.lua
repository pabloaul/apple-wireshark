aacp_proto = Proto("aacp", "Advanced Accessory Control Profile")

local aacp_type = {
    [0x00] = "Connect",
    [0x01] = "Connect Response",
    [0x02] = "Disconnect",
    [0x03] = "Disconnect Response",
    [0x04] = "Message"
}

-------- aacp message enums  --------
local aacp_message_type = {
    [0x01] = "Capabilities Request",
    [0x02] = "Capabilities",
    [0x03] = "Battery Info Request",
    [0x04] = "Battery Info",
    [0x05] = "Ear Detection Request",
    [0x06] = "Ear Detection",
    [0x07] = "Bud Role Request",
    [0x08] = "Bud Role",
    [0x09] = "Control",
    [0x0B] = "Device List",
    [0x0C] = "MAC Address",
    [0x0D] = "Stream State Info Request",
    [0x0E] = "Audio Source",
    [0x0F] = "Set Notification Filter",
    [0x10] = "Smart Routing",
    [0x11] = "Smart Routing",
    [0x12] = "Easy Pair Request?",
    [0x14] = "Connect Priority List",
    [0x15] = "Triangle Status Request",
    [0x16] = "Magnet Link",
    [0x17] = "BuddyCommand",
    [0x19] = "Stem Press",
    [0x1A] = "Rename",
    [0x1B] = "Timestamp",
    [0x1D] = "Information",
    [0x1E] = "Send External Accessory Session Packet",
    [0x1F] = "Notify Session State?",
    [0x20] = "Send Remote Firmware Auth Data",
    [0x21] = "Unknown",
    [0x22] = "Case Info Request",
    [0x24] = "Send Device Info?",
    [0x26] = "Certificates Request",
    [0x27] = "Certificates",
    [0x28] = "Gyro Info",
    [0x29] = "Set Country Code",
    [0x2B] = "Stream State Info",
    [0x2C] = "GAPA Challenge",
    [0x2D] = "Connected Devices Request",
    [0x2E] = "Connected Devices",
    [0x30] = "Magic Keys Request",
    [0x31] = "Magic Keys",
    [0x32] = "Magic Keys",
    [0x40] = "Unknown",
    [0x44] = "Send Smart Routing 2.0 Info",
    [0x45] = "Fast Connect Complete?",
    [0x47] = "Bud Swap 2.0 Procedure?",
    [0x48] = "Swap Imminent Confirm?",
    [0x49] = "Bud Swap 2.0 Completion?",
    [0x4A] = "Swap Complete Confirm?",
    [0x4B] = "Conversational Awareness",
    [0x4C] = "Adaptive Volume Message",
    [0x4D] = "Source Feature Capabilities",
    [0x4E] = "Feature ProxCard Status Update",
    [0x4F] = "UARP Data",
    [0x50] = "Unknown",
    [0x52] = "Source Context",
    [0x53] = "PME Config",
    [0x54] = "Set Band Edges",
    [0x55] = "Unknown",
    [0x56] = "USB Spatial Sensor Data Request",
    [0x57] = "Sleep Detection Update",
    [0x58] = "Unknown",
    [0x59] = "Dynamic End Of Charge",
    [0x60] = "Personal Translation",
}

local battery_component = {
    [0x08] = "Case",
    [0x04] = "Left",
    [0x02] = "Right",
    [0x01] = "Headset"
}

local battery_status = {
    [0x05] = "Charging/Disconnected",
    [0x04] = "Disconnected",
    [0x02] = "Discharging",
    [0x01] = "Charging",
    [0x00] = "Unknown"
}

local ear_detection = {
    [0x03] = "Disconnected",
    [0x02] = "In Case",
    [0x01] = "Out of Ear",
    [0x00] = "In Ear"
}

local bud_role = {
    [0x01] = "Left is primary",
    [0x02] = "Right is primary"
}

-------- aacp control enums --------
local aacp_control_type = {
    [0x01] = "Mic Mode",
    [0x02] = "Scan",
    [0x03] = "Reset",
    [0x04] = "Basic Double Tap Mode",
    [0x05] = "Button Send Mode",
    [0x06] = "Ownership state",
    [0x07] = "Tap Interval",
    [0x08] = "Bud Role", -- request connected bud to go secondary
    [0x09] = "Debug Get Data",
    [0x0A] = "In Ear Detection",
    [0x0B] = "Jitter Buffer", -- aka "Dynamic Latency"
    [0x0C] = "Double Tap Mode",
    [0x0D] = "Listen Mode",
    [0x0E] = "Heart Rate Monitor",
    [0x0F] = "Heart Rate Monitor",
    [0x10] = "Unknown/Unassigned",
    [0x11] = "Switch Control",
    [0x12] = "Voice Trigger",
    [0x13] = "DoAP mode", -- "Dictation over AirPods" for Siri
    [0x14] = "Single Click",
    [0x15] = "Double Click",
    [0x16] = "Click and Hold",
    [0x17] = "Double Click Interval",
    [0x18] = "Click and Hold Interval",
    [0x19] = "Unknown/Unassigned",
    [0x1A] = "Listening Mode Configs",
    [0x1B] = "One Bud ANC Mode",
    [0x1C] = "Crown Rotation Direction",
    [0x1D] = "Unknown/Unassigned",
    [0x1E] = "Auto Answer Mode",
    [0x1F] = "Chime Volume",
    [0x20] = "Smart Routing Mode",
    [0x21] = "Unknown/Unassigned",
    [0x22] = "HFP Uplink Mode",
    [0x23] = "Volume Swipe Interval",
    [0x24] = "Call Management Config",
    [0x25] = "Volume Swipe Mode",
    [0x26] = "Adaptive Volume",
    [0x27] = "Software Mute",
    [0x28] = "Conversation Detect",
    [0x29] = "Selective Speech Listening",
    [0x2A] = "Unknown/Unassigned",
    [0x2B] = "Unknown/Unassigned",
    [0x2C] = "Hearing Aid",
    [0x2D] = "Unknown/Unassigned",
    [0x2E] = "Auto ANC Strength",
    [0x2F] = "Hearing Aid Gain Swipe",
    [0x30] = "Heart Rate Monitor",
    [0x31] = "In-Case Tone",
    [0x32] = "Siri Multitone",
    [0x33] = "Hearing Assist",
    [0x34] = "Allow Off Option",
    [0x35] = "Sleep Detection",
    [0x36] = "Allow Auto Connect from Audio Accessory",
    [0x37] = "Hearing Protection PPE",
    [0x38] = "PPE Cap Level Config",
    [0x39] = "Raw Gestures Config",
    [0x3A] = "Allow Temporary Managed Pairing",
    [0x3B] = "Dynamic End of Charge",
    [0x3C] = "System Siri Mode",
    [0x3D] = "Hearing Aid Generic", -- "hearingAidV2SourceRegionSupport"
    [0x3E] = "Uplink EQ Bud",
    [0x3F] = "Uplink EQ Source",
    [0x40] = "In Case Tone Volume",
    [0x41] = "Disable Button Input"
}

local f = aacp_proto.fields
    f.type = ProtoField.uint16("aacp.type", "Type", base.HEX, aacp_type)
    f.service = ProtoField.uint16("aacp.service", "Service", base.DEC)
    f.status = ProtoField.uint16("aacp.status", "Status", base.HEX)
    f.major = ProtoField.uint16("aacp.major", "Major Version", base.DEC)
    f.minor = ProtoField.uint16("aacp.minor", "Minor Version", base.DEC)
    f.features = ProtoField.uint64("aacp.features", "Feature Flags", base.HEX)
    f.message_type = ProtoField.uint16("aacp.message_type", "Type", base.HEX, aacp_message_type)
    f.control_type = ProtoField.uint8("aacp.control_type", "Type", base.HEX, aacp_control_type)
    f.data = ProtoField.bytes("aacp.data", "Trailing Data", base.NONE)

function aacp_proto.dissector(buffer, pinfo, tree)
    if buffer():len() < 4 then return end -- skip if header is missing
    pinfo.cols.protocol = aacp_proto.name

    local subtree = tree:add(aacp_proto, buffer(), "Apple Advanced Accessory Control Profile")
    local offset = 0

    local type = buffer(offset, 2):le_uint()
    pinfo.cols.info:set("[" .. (aacp_type[type] or "Undiscovered") .. "] ")
    subtree:add_le(f.type, buffer(offset, 2))
    offset = offset + 2

    subtree:add_le(f.service, buffer(offset, 2))
    offset = offset + 2

    if type == 0x00 then -- Connect
        subtree:add_le(f.major, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.minor, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.features, buffer(offset, 8))
        offset = offset + 8
    elseif type == 0x01 then -- Connect Response
        subtree:add_le(f.status, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.major, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.minor, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.features, buffer(offset, 8))
        offset = offset + 8
    elseif type == 0x02 then -- Disconnect
        subtree:add_le(f.status, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x03 then -- Disconnect Response
    elseif type == 0x04 then -- Message
        local message_tree = subtree:add(aacp_proto, buffer(offset), "Message")
        offset = offset + aacp_message(buffer(offset), pinfo, message_tree)
    end

    if buffer(offset):len() ~= 0 then -- trailing data
        subtree:add(f.data, buffer(offset))
    end

    return offset
end

function aacp_message(buffer, pinfo, tree)
    local offset = 0

    local type = buffer(offset, 2):le_uint()
    pinfo.cols.info:append(aacp_message_type[type] or "Unknown Message")
    tree:set_text(aacp_message_type[type] or "Unknown Message")
    tree:add_le(f.message_type, buffer(offset, 2))
    offset = offset + 2

    if type == 0x04 then -- Battery Info
        local battery_count = buffer(offset, 1):uint()
        offset = offset + 1

        for i = 0, battery_count - 1, 1 do
            local component = buffer(offset, 1):uint()
            local chargevol = buffer(offset + 2, 1):uint()
            local status = buffer(offset + 3, 1):uint()

            tree:add(aacp_proto, buffer(offset, 5), battery_component[component]..": "..chargevol.."% ("..(battery_status[status] or "Unknown")..")")

            offset = offset + 5
        end
    elseif type == 0x06 then -- Ear Detection
        local primary = ear_detection[buffer(offset, 1):uint()]
        tree:add(aacp_proto, buffer(offset, 1), "Primary: " .. primary)
        offset = offset + 1

        local secondary = ear_detection[buffer(offset, 1):uint()]
        tree:add(aacp_proto, buffer(offset, 1), "Secondary: " .. secondary)
        offset = offset + 1
    elseif type == 0x08 then -- Bud Role
        local role = buffer(offset, 1):uint()
        tree:add(aacp_proto, buffer(offset, 1), bud_role[role])
        offset = offset + 1
    elseif type == 0x09 then -- Control Command
        local control_tree = tree:add(aacp_proto, buffer(offset), "Control")
        offset = offset + aacp_control(buffer(offset), pinfo, control_tree)
    end

    return offset
end

function aacp_control(buffer, pinfo, tree)
    local offset = 0

    local type = buffer(offset, 1):uint()
    pinfo.cols.info:append(", "..(aacp_control_type[type] or "Unknown Control"))
    tree:set_text(aacp_control_type[type] or "Unknown Control")
    tree:add(f.control_type, buffer(offset, 1))
    offset = offset + 1



    return offset
end

local l2cap_psm = DissectorTable.get("btl2cap.psm")
l2cap_psm:add(0x1001, aacp_proto)

local l2cap_cid = DissectorTable.get("btl2cap.cid")
l2cap_cid:add_for_decode_as(aacp_proto)
