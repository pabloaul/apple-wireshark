uarp_proto = Proto("uarp", "Apple Universal Accessory Restore Protocol")

local enums = require("uarp_enums")

local f = rtbuddy_proto.fields
    f.type = ProtoField.uint16("uarp.type", "Type", base.HEX, enums.message_type)
    f.length = ProtoField.uint16("uarp.length", "Length", base.DEC)
    f.seq = ProtoField.uint16("uarp.seq", "Sequence", base.DEC)
    f.data = ProtoField.bytes("uarp.data", "Data", base.NONE)
    f.version = ProtoField.uint16("uarp.version", "Version", base.HEX)
    f.fw_apply_status = ProtoField.uint16("uarp.fw_apply_status", "Firmware Application Status", base.HEX, enums.firmware_application_status)
    f.unknown = ProtoField.bytes("uarp.unknown", "Unknown", base.NONE)

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

    if type == 0x00 then
    elseif type == 0x01 then
        subtree:add(f.version, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x02 then
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.version, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x03 then
        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4
    elseif type == 0x04 then
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        local len = buffer(offset, 2):uint()
        offset = offset + 2

        if len ~= 0 then
            subtree:add(f.data, buffer(offset, len))
            offset = offset + len
        end
    elseif type == 0x05 or type == 0x0D then
        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.unknown, buffer(offset, 8))
        offset = offset + 8

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x06 then
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x07 then
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        local len = buffer(offset, 2):uint()
        offset = offset + 2

        subtree:add(f.data, buffer(offset, len))
        offset = offset + len
    elseif type == 0x09 then
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x0A then
    elseif type == 0x0B then
        subtree:add(f.fw_apply_status, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x0F then
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x11 then
        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4
    elseif type == 0x12 then
        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4
    elseif type == 0x17 then
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x18 then
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x1B then -- downstream endpoint message
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        offset = offset + Dissector.get("uarp"):call(buffer(offset):tvb(), pinfo, tree)
        pinfo.cols.info:prepend("[Downstream] ")
    elseif type == 0x1C then
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    end

    if buffer(offset):len() ~= 0 then
        subtree:add(f.data, buffer(offset))
        offset = offset + buffer(offset):len()
    end

    return offset
end
