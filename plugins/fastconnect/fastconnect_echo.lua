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

register_postdissector(fastconnect_l2c_echo_proto)
