uarp_proto = Proto("uarp", "Apple Unified Accessory Restore Protocol")

local cmd_type = {
    [0x0000] = "Hello",
    [0x0001] = "Connect",
    [0x0002] = "Conenct Response",
    [0x0003] = "Read Register?",
    [0x0004] = "Read Register Response?",

    [0x0005] = "?",
    [0x0006] = "?",
    [0x0007] = "?",
    [0x0009] = "?",
    [0x000D] = "?",
    [0x000F] = "?",
    [0x0011] = "?",
    [0x0012] = "?",

    [0xFFFF] = "?",
}

local f = rtbuddy_proto.fields
    f.type = ProtoField.uint16("uarp.type", "Type", base.HEX, cmd_type)
    f.length = ProtoField.uint16("uarp.length", "Length", base.DEC)
    f.seq = ProtoField.uint16("uarp.seq", "Sequence", base.DEC)
    f.data = ProtoField.bytes("uarp.data", "Data", base.NONE)

function uarp_proto.dissector(buffer, pinfo, tree)
    if buffer():len() == 0 then return end
    pinfo.cols.protocol = uarp_proto.name

    local subtree = tree:add(uarp_proto, buffer(), "Apple Unified Accessory Restore Protocol")
    local offset = 0

    local type = buffer(offset, 2):uint()
    subtree:add(f.type, buffer(offset, 2))
    offset = offset + 2

    local length = buffer(offset, 2):uint()
    subtree:add(f.length, buffer(offset, 2))
    offset = offset + 2

    subtree:add(f.seq, buffer(offset, 2))
    offset = offset + 2

    subtree:add(f.data, buffer(offset, length))
    offset = offset + length

    return offset
end
