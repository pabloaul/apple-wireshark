aacp_proto = Proto("aacp", "Advanced Accessory Control Profile")

local aacp_type = {
    [0x00] = "Connect",
    [0x01] = "Connect Response",
    [0x02] = "Disconnect",
    [0x03] = "Disconnect Response",
    [0x04] = "Message"
}

local f = aacp_proto.fields
    f.type = ProtoField.uint16("aacp.type", "Type", base.HEX, aacp_type)
    f.service = ProtoField.uint16("aacp.service", "Service", base.DEC)
    f.status = ProtoField.uint16("aacp.status", "Status", base.HEX)
    f.major = ProtoField.uint16("aacp.major", "Major Version", base.DEC)
    f.minor = ProtoField.uint16("aacp.minor", "Minor Version", base.DEC)
    f.features = ProtoField.uint64("aacp.features", "Feature Flags", base.HEX)
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
    end

    if buffer(offset):len() ~= 0 then -- trailing data
        subtree:add(f.data, buffer(offset))
    end

    return offset
end

local l2cap_psm = DissectorTable.get("btl2cap.psm")
l2cap_psm:add(0x1001, aacp_proto)

local l2cap_cid = DissectorTable.get("btl2cap.cid")
l2cap_cid:add_for_decode_as(aacp_proto)
