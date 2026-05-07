fastconnect_proto = Proto("fastconnect", "Apple FastConnect")

local enums = require("fastconnect_enums")

local f = fastconnect_proto.fields
    f.state = ProtoField.uint16("fastconnect.state", "State", base.HEX, enums.state)
    f.magic = ProtoField.uint16("fastconnect.magic", "Magic", base.DEC)
    f.cid = ProtoField.uint16("fastconnect.cid", "Channel ID", base.HEX)
    f.psm = ProtoField.uint16("fastconnect.psm", "PSM", base.HEX, enums.psm_mapping)
    f.mtu = ProtoField.uint16("fastconnect.mtu", "MTU", base.DEC)
    f.type = ProtoField.uint16("fastconnect.type", "Type", base.DEC, enums.fc_type)
    f.general_type = ProtoField.uint8("fastconnect.general_type", "Type", base.HEX, enums.fc_general_type)
    f.descriptor_type = ProtoField.uint8("fastconnect.descriptor_type", "Type", base.HEX)
    f.descriptor = ProtoField.uint32("fastconnect.descriptor", "Descriptor", base.HEX, enums.descriptor_mapping)
    f.unknown = ProtoField.bytes("fastconnect.data", "Unknown")

function fastconnect_proto.dissector(buffer, pinfo, tree)
    pinfo.cols.protocol = fastconnect_proto.name
    local subtree = tree:add(fastconnect_proto, buffer())
    local offset = 0

    local state = buffer(offset, 2):le_uint()
    subtree:add_le(f.state, buffer(offset, 2))
    pinfo.cols.info:set(enums.state[state])
    offset = offset + 2

    subtree:add_le(f.magic, buffer(offset, 2))
    offset = offset + 2

    if state == 0x01 or state == 0x02 then
        local cid = buffer(offset, 2):le_uint()
        subtree:add_le(f.cid, buffer(offset, 2))
        DissectorTable.get("btl2cap.cid"):add(cid, Dissector.get("fastconnect"))
        offset = offset + 2

    elseif state == 0x03 or state == 0x04 or state == 0x05 or state == 0x06 then
        while offset < buffer():len() do
            local type = buffer(offset, 2):le_uint()
            local tlvtree = subtree:add_le(f.type, buffer(offset, 2))
            offset = offset + 2

            if type == 0x01 then
                local tlv_len = buffer(offset, 2):le_uint()
                offset = offset + 2

                offset = offset + parse_general(buffer(offset, tlv_len), pinfo, tlvtree)
            elseif type == 0x02 then
                return offset + parse_descriptor(buffer(offset), pinfo, tlvtree)
            else
                return offset -- panic!
            end
        end
    end

    subtree:add(f.unknown, buffer(offset))
end


function parse_general(buffer, pinfo, tree)
    local offset = 0

    while offset < buffer():len() do
        local type = buffer(offset, 1):uint()
        local typetree = tree:add(f.general_type, buffer(offset, 1))
        offset = offset + 1

        local len = buffer(offset, 1):uint()
        offset = offset + 1

        local value = buffer(offset, len)
        typetree:add(f.unknown, buffer(offset, len))
        offset = offset + len
    end

    return offset
end

function parse_descriptor(buffer, pinfo, tree)
    local offset = 0

    while offset < buffer():len() do
        local descriptortree = tree:add_le(f.descriptor, buffer(offset, 4))
        offset = offset + 4

        local payload_len = buffer(offset, 2):le_uint()
        offset = offset + 2

        offset = offset + parse_descriptor_payload(buffer(offset, payload_len), pinfo, descriptortree)
    end

    return offset
end

function parse_descriptor_payload(buffer, pinfo, tree)
    if buffer():len() == 0 then return 0 end
	local offset = 0

    while offset < buffer():len() do
        local type = buffer(offset, 1):uint()
        local typetree = tree:add(f.descriptor_type, buffer(offset, 1))
        offset = offset + 1

        local len = buffer(offset, 1):uint()
        offset = offset + 1

        if type == 0x01 then
            local cid = buffer(offset, 2):le_uint()
            typetree:add_le(f.cid, buffer(offset, 2))

            local psm = buffer(offset + 2, 2):le_uint()
            typetree:add_le(f.psm, buffer(offset + 2, 2))

            typetree:add_le(f.mtu, buffer(offset + 4, 2))
            typetree:add(f.unknown, buffer(offset + 6, 1))

            DissectorTable.get("btl2cap.cid"):add(cid, Dissector.get((enums.psm_mapping[psm] or "data")))
        else
            typetree:add(f.unknown, buffer(offset, len))
        end
        offset = offset + len
    end

    return offset
end

local l2cap_cid = DissectorTable.get("btl2cap.cid")
l2cap_cid:add_for_decode_as(fastconnect_proto)
