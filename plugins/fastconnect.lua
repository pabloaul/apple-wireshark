fastconnect_l2c_echo_proto = Proto("fastconnect_l2c_echo", "Apple FastConnect via L2CAP Echo")

l2cap_cid = Field.new("btl2cap.cid")
l2cap_cmd = Field.new("btl2cap.cmd_code")
l2cap_data = Field.new("btl2cap.data")

function fastconnect_l2c_echo_proto.dissector(buffer, pinfo, tree)
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

local f = fastconnect_proto.fields
    f.state = ProtoField.uint16("fastconnect.state", "State", base.HEX, fc_state)
    f.magic = ProtoField.uint16("fastconnect.magic", "Magic", base.DEC)
    f.cid = ProtoField.uint16("fastconnect.cid", "L2CAP CID", base.HEX)
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
        offset = offset + 2

        DissectorTable.get("btl2cap.cid"):add(cid, Dissector.get("fastconnect"))
    end

    subtree:add(f.unknown, buffer(offset))
end

local l2cap_cid = DissectorTable.get("btl2cap.cid")
l2cap_cid:add_for_decode_as(fastconnect_proto)

register_postdissector(fastconnect_l2c_echo_proto)
