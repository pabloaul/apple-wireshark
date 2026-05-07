magicpairing_proto = Proto("magicpairing", "Apple MagicPairing")
-- This dissector is pretty much 1:1 -> Dennis Heinze, Jiska Classen, and Felix Rohrbach. 2020. MagicPairing: Apple’s Take on Securing Bluetooth Peripherals.
-- tested with magicpairing version 1

local enums = require("magicpairing_enums")

local f = magicpairing_proto.fields
    f.type = ProtoField.uint8("magicpairing.type", "Type", base.HEX, enums.type)
    f.version = ProtoField.uint8("magicpairing.version", "Version", base.HEX)
    f.keytype = ProtoField.uint16("magicpairing.keytype", "Key Type", base.HEX, enums.key_type)
    f.keylen = ProtoField.uint16("magicpairing.keylen", "Key Length", base.DEC)
    f.keycount = ProtoField.uint8("magicpairing.keycount", "Key Count", base.DEC)
    f.status = ProtoField.uint8("magicpairing.status", "Status", base.HEX, enums.status)
    f.key = ProtoField.bytes("magicpairing.key", "Key", base.NONE)
    f.data = ProtoField.bytes("magicpairing.data", "Trailing Data", base.NONE)
    f.unknown = ProtoField.bytes("magicpairing.unknown", "Unknown", base.NONE)

function magicpairing_proto.dissector(buffer, pinfo, tree)
    if buffer():len() == 0 then return end
    pinfo.cols.protocol = magicpairing_proto.name

    local subtree = tree:add(magicpairing_proto, buffer(), "Apple MagicPairing")
    local offset = 0

    local type = buffer(offset, 1):uint()
    pinfo.cols.info:set("[" .. (enums.type[type] or "Undiscovered") .. "] ")
    subtree:add(f.type, buffer(offset, 1))
    offset = offset + 1

    subtree:add(f.version, buffer(offset, 1))
    offset = offset + 1

    if type == 0x01 then -- Hint
        offset = offset + key_message(buffer(offset), pinfo, subtree)

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x02 then -- Ratcheting
        offset = offset + key_message(buffer(offset), pinfo, subtree)
    elseif type == 0x03 then -- AES SIV
        offset = offset + key_message(buffer(offset), pinfo, subtree)
    elseif type == 0x04 then -- Ratchet
        offset = offset + key_message(buffer(offset), pinfo, subtree)
    elseif type == 0xf0 then -- Ping
        return offset
    elseif type == 0xff then -- Status
        local status = buffer(offset, 1):uint()
        subtree:add(f.status, buffer(offset, 1))
        pinfo.cols.info:append(enums.status[status] or "Undiscovered")
        offset = offset + 1
    end

    if buffer(offset):len() ~= 0 then -- trailing data
        subtree:add(f.data, buffer(offset))
    end

    return offset
end

function key_message(buffer, pinfo, tree)
    local offset = 0

    local key_count = buffer(offset, 1):uint()
    tree:add(f.keycount, buffer(offset, 1))
    offset = offset + 1

    for i = 0, key_count-1, 1 do
        local key = tree:add_le(f.keytype, buffer(offset, 2))
        offset = offset + 2

        local keylen = buffer(offset, 2):le_uint()
        key:add_le(f.keylen, buffer(offset, 2))
        offset = offset + 2

        key:add(f.key, buffer(offset, keylen))
        offset = offset + keylen
    end

    return offset
end

local l2cap_cid = DissectorTable.get("btl2cap.cid")
l2cap_cid:add(0x30, magicpairing_proto)
