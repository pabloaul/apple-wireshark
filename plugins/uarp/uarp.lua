uarp_proto = Proto("uarp", "Apple Universal Accessory Restore Protocol")

local enums = require("uarp_enums")

local f = rtbuddy_proto.fields
    f.type = ProtoField.uint16("uarp.type", "Type", base.HEX, enums.message_type)
    f.length = ProtoField.uint16("uarp.length", "Length", base.DEC)
    f.seq = ProtoField.uint16("uarp.seq", "Sequence", base.DEC)
    f.data = ProtoField.bytes("uarp.data", "Data", base.NONE)

function uarp_proto.dissector(buffer, pinfo, tree)
    if buffer():len() == 0 then return end
    pinfo.cols.protocol = uarp_proto.name

    local subtree = tree:add(uarp_proto, buffer(), "Apple Universal Accessory Restore Protocol")
    local offset = 0

    local type = buffer(offset, 2):uint()
    subtree:add(f.type, buffer(offset, 2))
    pinfo.cols.info:set("[" .. (enums.message_type[type] or "Undiscovered") .. "] ")
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
