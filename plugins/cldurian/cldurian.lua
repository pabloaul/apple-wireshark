cldurian_proto = Proto("cldurian", "Apple CoreLocation Durian")

local enums = require("cldurian_enums")

local f = cldurian_proto.fields
    f.type = ProtoField.uint8("cldurian.type", "Type", base.HEX, enums.type)
    f.length = ProtoField.uint24("cldurian.length", "Length", base.DEC)
    f.data = ProtoField.bytes("cldurian.data", "Data", base.NONE)

function cldurian_proto.dissector(buffer, pinfo, tree)
    if buffer():len() == 0 then return end
    pinfo.cols.protocol = cldurian_proto.name

    local subtree = tree:add(cldurian_proto, buffer(), "Apple CoreLocation Durian")
    local offset = 0

    local type = buffer(offset, 1):uint()
    subtree:add(f.type, buffer(offset, 1))
    pinfo.cols.info:set(enums.airtag_tasks[type])
    offset = offset + 1

    if type == 0x00 then
        local ackd_type = buffer(offset, 1):uint()
        subtree:add(f.type, buffer(offset, 1)):prepend_text("Acknowledged ")
        pinfo.cols.info:append(" : "..enums.airtag_tasks[ackd_type])
        offset = offset + 1
    end


    if buffer(offset):len() ~= 0 then -- trailing data
        tree:add(f.data, buffer(offset))
        offset = offset + buffer(offset):len()
    end

    return offset
end
