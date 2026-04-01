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
    f.data = ProtoField.bytes("aacp.data", "Trailing Data", base.NONE)

function aacp_proto.dissector(buffer, pinfo, tree)
    if buffer():len() < 4 then return end -- skip if header is missing
    pinfo.cols.protocol = aacp_proto.name

    local subtree = tree:add(aacp_proto, buffer(), "Apple Advanced Accessory Control Profile")
    local offset = 0

    subtree:add_le(f.type, buffer(offset, 2))
    offset = offset + 2

    subtree:add_le(f.service, buffer(offset, 2))
    offset = offset + 2

    subtree:add(f.data, buffer(offset))

    return offset
end

local l2cap_psm = DissectorTable.get("btl2cap.psm")
l2cap_psm:add(0x1001, aacp_proto)

local l2cap_cid = DissectorTable.get("btl2cap.cid")
l2cap_cid:add_for_decode_as(aacp_proto)
