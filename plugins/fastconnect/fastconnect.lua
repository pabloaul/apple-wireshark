fastconnect_proto = Proto("fastconnect", "Apple FastConnect")

local enums = require("fastconnect_enums")

local f = fastconnect_proto.fields
    f.state = ProtoField.uint16("fastconnect.state", "State", base.HEX, enums.state)
    f.magic = ProtoField.uint16("fastconnect.magic", "Magic", base.DEC)
    f.cid = ProtoField.uint16("fastconnect.cid", "Channel ID", base.HEX)
    f.version = ProtoField.uint32("fastconnect.version", "Version", base.HEX)
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

        -- 0x0004 on both airpods and ios, unknown
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.version, buffer(offset, 4))
        offset = offset + 4

        -- 0x1600... on airpods, 0x1500... on ios
        subtree:add(f.unknown, buffer(offset, 8))
        offset = offset + 8

        -- 0xff30fb5e on airpods, 0xc426a000 on ios
        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4

        -- 0x08000000 on airpods, varies on ios
        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 8))
        offset = offset + 8

        if state == 0x01 then -- initial has two more leading bytes
            subtree:add(f.unknown, buffer(offset, 2))
            offset = offset + 2
        end

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

    if buffer(offset):len() ~= 0 then
        subtree:add(f.unknown, buffer(offset))
        offset = offset + buffer(offset):len()
    end
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
        local descriptor = buffer(offset, 4):le_uint()
        local descriptortree = tree:add_le(f.descriptor, buffer(offset, 4))
        offset = offset + 4

        local payload_len = buffer(offset, 2):le_uint()
        offset = offset + 2

        offset = offset + parse_descriptor_payload(buffer(offset, payload_len), pinfo, descriptortree, descriptor)
    end

    return offset
end

function parse_descriptor_payload(buffer, pinfo, tree, descriptor)
    if buffer():len() == 0 then return 0 end
	local offset = 0

    while offset < buffer():len() do
        local type = buffer(offset, 1):uint()
        local typetree = tree:add(f.descriptor_type, buffer(offset, 1))
        offset = offset + 1

        local len = buffer(offset, 1):uint()
        offset = offset + 1

        annotate_fc_setting_types(typetree, type, descriptor)

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

function annotate_fc_setting_types(tree, type, descriptor)
    tree:append_text(" ")

    if type < 0x10 then -- annotate common FC setting types
        tree:append_text(enums.fc_common[type])
        return
    end

    if descriptor == 0x00000001 then
        tree:append_text(enums.fc_hfp[type])
    elseif descriptor == 0x00000008 then
        tree:append_text(enums.fc_avrcp[type])
    elseif descriptor == 0x00000010 then
        tree:append_text(enums.fc_a2dp[type])
    elseif descriptor == 0x00080000 then
        tree:append_text(enums.fc_aacp[type])
    elseif descriptor == 0x00100000 then
        tree:append_text(enums.fc_gatt[type])
    end
end

local l2cap_cid = DissectorTable.get("btl2cap.cid")
l2cap_cid:add_for_decode_as(fastconnect_proto)
