enums = require("aacp_enums")
parse_message = require("aacp_parse_message")

aacp_proto = Proto("aacp", "Advanced Accessory Control Profile")
-- tested with AACP version 1.2/1.3

local f = aacp_proto.fields
-- AACP:
    f.type = ProtoField.uint16("aacp.type", "Type", base.HEX, enums.type)
    f.service = ProtoField.uint16("aacp.service", "Service", base.DEC)
    f.status = ProtoField.uint16("aacp.status", "Status", base.HEX)
    f.major = ProtoField.uint16("aacp.major", "Major Version", base.DEC)
    f.minor = ProtoField.uint16("aacp.minor", "Minor Version", base.DEC)
    f.features = ProtoField.uint64("aacp.features", "Feature Flags", base.HEX)
-- AACP/Message:
    f.message_type = ProtoField.uint16("aacp.message_type", "Type", base.HEX, enums.message_type)
    f.tipi_variant = ProtoField.uint8("aacp.tipi_variant", "TiPi Variant", base.HEX, enums.tipi_variant)
-- AACP/Message/Control:
    f.control_type = ProtoField.uint8("aacp.control_type", "Type", base.HEX, enums.control_type)
-- AACP/Message/MagicPairing:
    f.keytype = ProtoField.uint16("aacp.mp_keytype", "Key Type", base.HEX, enums.mp_key_type)
    f.keylen = ProtoField.uint16("aacp.mp_keylen", "Key Length", base.DEC)
    f.keycount = ProtoField.uint8("aacp.mp_keycount", "Key Count", base.DEC)
    f.key = ProtoField.bytes("aacp.mp_key", "Key", base.NONE)
-- Misc:
    f.ether = ProtoField.ether("aacp.mac", "MAC Address")
    f.opack_data = ProtoField.protocol("aacp.opack_data", "OPACK Data")
    f.uarp_data = ProtoField.protocol("aacp.uarp_data", "UARP Data")
    f.unknown = ProtoField.bytes("aacp.unknown", "Unknown", base.NONE)
    f.data = ProtoField.bytes("aacp.data", "Trailing Data", base.NONE)

function aacp_proto.dissector(buffer, pinfo, tree)
    if buffer():len() < 4 then return 0 end -- skip if header is missing
    pinfo.cols.protocol = aacp_proto.name

    local subtree = tree:add(aacp_proto, buffer(), "Apple Advanced Accessory Control Profile")
    local offset = 0

    local type = buffer(offset, 2):le_uint()
    pinfo.cols.info:set("[" .. (enums.type[type] or "Undiscovered") .. "] ")
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
        subtree:add_le(f.status, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x04 then -- Message
        local message_tree = subtree:add(aacp_proto, buffer(offset), "Message")
        offset = offset + parse_message.msg(buffer(offset), pinfo, message_tree, f)
    end

    if buffer(offset):len() ~= 0 then -- trailing data
        subtree:add(f.data, buffer(offset))
    end

    return offset
end

-- automatic ios / fastconnect attachment:
-- have fastconnect.lua installed

-- automatic android / non-fastconnect attachment:
local l2cap_psm = DissectorTable.get("btl2cap.psm")
l2cap_psm:add(0x1001, aacp_proto)

-- manual attachment:
local l2cap_cid = DissectorTable.get("btl2cap.cid")
l2cap_cid:add_for_decode_as(aacp_proto)
