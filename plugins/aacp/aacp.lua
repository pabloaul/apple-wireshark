aacp_proto = Proto("aacp", "Advanced Accessory Control Profile")
-- tested with AACP version 1.2/1.3

local f = require("aacp_fields")
local enums = require("aacp_enums")
local parse_message = require("aacp_parse_message")

aacp_proto.experts.incomplete = ProtoExpert.new("aacp_proto.incomplete", "Unparsed Data", expert.group.UNDECODED, expert.severity.NOTE)

function aacp_proto.dissector(buffer, pinfo, tree)
    if buffer():len() < 4 then return 0 end -- skip if header is missing
    pinfo.cols.protocol = aacp_proto.name

    local subtree = tree:add(aacp_proto, buffer(), "Apple Advanced Accessory Control Profile")
    local offset = 0

    local type = buffer(offset, 2):le_uint()
    pinfo.cols.info:set("[" .. (enums.type[type] or "Undiscovered") .. "] ")
    subtree:add_le(f.type, buffer(offset, 2))
    offset = offset + 2

    subtree:add_le(f.service, buffer(offset, 2))
    offset = offset + 2

    if type == 0x00 then -- Connect
        subtree:add_le(f.major, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.minor, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.features, buffer(offset, 8))
        offset = offset + 8
    elseif type == 0x01 then -- Connect Response
        subtree:add_le(f.status, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.major, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.minor, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.features, buffer(offset, 8))
        offset = offset + 8
    elseif type == 0x02 then -- Disconnect
        subtree:add_le(f.status, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x03 then -- Disconnect Response
        subtree:add_le(f.status, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x04 then -- Message
        local message_tree = subtree:add(aacp_proto, buffer(offset), "Message")
        offset = offset + parse_message.msg(buffer(offset), pinfo, message_tree)
    end

    if buffer(offset):len() ~= 0 then -- trailing data
  		subtree:add_proto_expert_info(aacp_proto.experts.incomplete, "Undecoded")
        subtree:add(f.data, buffer(offset))
    end

    return offset
end

-- automatic ios / fastconnect attachment:
-- have fastconnect.lua installed

-- automatic android / non-fastconnect attachment:
local l2cap_psm = DissectorTable.get("btl2cap.psm")
l2cap_psm:add(0x1001, aacp_proto)

-- manual attachment:
local l2cap_cid = DissectorTable.get("btl2cap.cid")
l2cap_cid:add_for_decode_as(aacp_proto)
