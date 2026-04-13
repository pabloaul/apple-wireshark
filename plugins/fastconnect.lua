fastconnect_l2c_echo_proto = Proto("fastconnect_l2c_echo", "Apple FastConnect via L2CAP Echo")

l2cap_cid = Field.new("btl2cap.cid")
l2cap_cmd = Field.new("btl2cap.cmd_code")
l2cap_data = Field.new("btl2cap.data")

function fastconnect_l2c_echo_proto.dissector(buffer, pinfo, tree)
    -- ensure fields exist
    if l2cap_cid() == nil or l2cap_cmd() == nil or l2cap_data() == nil then return end

    -- match l2cap signaling channel
    if l2cap_cid()() ~= 0x0001 then return end

    -- match l2cap echo/reply
    if l2cap_cmd()() ~= 8 and l2cap_cmd()() ~= 9 then return end

    local initial_message = false
    local offset = 0

    -- handle fastconnect initial length bytes
    if l2cap_cmd()() == 8 then initial_message = true end
    local length = l2cap_data()():len()
    if initial_message and l2cap_data()():le_uint(0,2) ~= length - 2 then return end
    if initial_message then offset = offset + 2 end

    -- match fastconnect magic value
    if l2cap_data()():le_uint(offset+2, 1) ~= 5 then return end

    local fc_buffer = l2cap_data()():subset(offset, length-2):tvb("FastConnect via L2CAP Echo")

    Dissector.get("fastconnect"):call(fc_buffer, pinfo, tree)
end

--- FastConnect ---

fastconnect_proto = Proto("fastconnect", "Apple FastConnect")

local fc_state = {
    [0x00] = "Idle",
    [0x01] = "Initial",
    [0x02] = "Echo Sent",
    [0x03] = "Echo Received",
    [0x04] = "Descriptor Sent",
    [0x05] = "Descriptor Received",
    [0x06] = "Config Sent",
    [0x07] = "Config Received",
    [0x08] = "Setup Complete Sent",
    [0x09] = "Setup Complete Received"
}

local fc_type = {
    [0x01] = "General",
    [0x02] = "Descriptors"
}

local fc_general_type = {
    [0x01] = "Version",
    [0x02] = "Unknown",
    [0x03] = "Unknown",
    [0x04] = "Unknown"
}

local fc_descriptor_type = {
    [0x01] = "L2CAP Configuration",
    [0x03] = "Unknown",
    [0x04] = "L2CAP Configuration Response",
    [0x10] = "Unknown",
    [0x11] = "Unknown",
    [0x12] = "Unknown",
    [0x13] = "Service Initial Commands",
    [0x14] = "Unknown",
    [0x15] = "Unknown",
    [0x16] = "Unknown",
    [0x17] = "Unknown",
    [0x18] = "Unknown",
    [0x19] = "Unknown",
    [0x1A] = "Unknown",
    [0x1B] = "Unknown",
    [0x1C] = "Unknown"
}

local psm_mapping = {
    [0x0003] = "btrfcomm",
    [0x0017] = "btavrcp",
    [0x0019] = "btavdtp",
    [0x001F] = "btatt",
    [0x03E9] = "aacp", -- apple bug?
    [0x1001] = "aacp",
}

local descriptor_mapping = {
    [0x00000001] = "RFCOMM/HFP?",
    [0x00000008] = "AVRCP",
    [0x00000010] = "AVDTP",
    [0x00080000] = "AACP",
    [0x00100000] = "GATT"
}

local f = fastconnect_proto.fields
    f.state = ProtoField.uint16("fastconnect.state", "State", base.HEX, fc_state)
    f.magic = ProtoField.uint16("fastconnect.magic", "Magic", base.DEC)
    f.cid = ProtoField.uint16("fastconnect.cid", "Channel ID", base.HEX)
    f.psm = ProtoField.uint16("fastconnect.psm", "PSM", base.HEX, psm_mapping)
    f.mtu = ProtoField.uint16("fastconnect.mtu", "MTU", base.DEC)
    f.type = ProtoField.uint16("fastconnect.type", "Type", base.DEC, fc_type)
    f.general_type = ProtoField.uint8("fastconnect.general_type", "Type", base.HEX, fc_general_type)
    f.descriptor_type = ProtoField.uint8("fastconnect.descriptor_type", "Type", base.HEX, fc_descriptor_type)
    f.descriptor = ProtoField.uint32("fastconnect.descriptor", "Descriptor", base.HEX, descriptor_mapping)
    f.unknown = ProtoField.bytes("fastconnect.data", "Unknown")

function fastconnect_proto.dissector(buffer, pinfo, tree)
    pinfo.cols.protocol = fastconnect_proto.name
    local subtree = tree:add(fastconnect_proto, buffer())
    local offset = 0

    local state = buffer(offset, 2):le_uint()
    subtree:add_le(f.state, buffer(offset, 2))
    pinfo.cols.info:set(fc_state[state])
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

            DissectorTable.get("btl2cap.cid"):add(cid, Dissector.get((psm_mapping[psm] or "data")))
        else
            typetree:add(f.unknown, buffer(offset, len))
        end
        offset = offset + len
    end

    return offset
end

local l2cap_cid = DissectorTable.get("btl2cap.cid")
l2cap_cid:add_for_decode_as(fastconnect_proto)

register_postdissector(fastconnect_l2c_echo_proto)
