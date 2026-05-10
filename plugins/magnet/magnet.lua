magnet_proto = Proto("magnet", "Apple Magnet")
-- based on Nils Rollshausen, WatchWitch: Investigating Apple Watch Interoperability and Security

local enums = require("magnet_enums")
local magnet_service_mapping = {} -- dissector state for mapping the service ID to a service name

local f = magnet_proto.fields
    f.type = ProtoField.uint8("magnet.type","Type", base.HEX, enums.type)
    f.len8 = ProtoField.uint8("magnet.len_old", "Length", base.DEC)
    f.len16 = ProtoField.uint16("magnet.len", "Length", base.DEC)
    f.service_count = ProtoField.uint8("magnet.service_count", "Service Count", base.DEC)
    f.service_id = ProtoField.uint16("magnet.sid", "Service ID", base.DEC)
    f.service_name = ProtoField.string("magnet.service_name", "Service Name", base.ASCII)
    f.service_flags = ProtoField.uint8("magnet.service_flags", "Service Flags", base.HEX)
    f.service_option = ProtoField.uint8("magnet.service_option", "Service Option", base.HEX)
    f.cid = ProtoField.uint16("magnet.cid","Channel ID", base.HEX)
    f.version = ProtoField.uint8("magnet.version", "Magnet Version", base.DEC)
    f.flags = ProtoField.uint32("magnet.flags", "Magnet Flags", base.HEX)
    f.timestamp = ProtoField.absolute_time("magnet.timestamp", "Timestamp", base.UTC)
    f.vid = ProtoField.uint16("magnet.vid","Vendor ID", base.HEX)
    f.pid = ProtoField.uint16("magnet.pid","Product ID", base.HEX)
    f.did_version = ProtoField.uint16("magnet.did_version","DID Version", base.HEX)
    f.chipset = ProtoField.uint16("magnet.chipset","Chipset", base.HEX, enums.did_chipset)
    f.unknown = ProtoField.bytes("magnet.data", "Unknown Data", base.NONE)

local service_to_dissector = { -- mapping magnet service name to dissector name
    ["CLink"] = "clink",
    ["CLinkHP"] = "clink",
    ["com.apple.BT.TS"] = "btts",
    ["com.apple.terminusLink"] = "nrlp",
    ["com.apple.terminusLink.urgent"] = "nrlp",
}

function magnet_proto.dissector(buffer, pinfo, tree)
    if buffer():len() == 0 then return end
    pinfo.cols.protocol = magnet_proto.name

    local subtree = tree:add(magnet_proto, buffer(), "Apple Magnet")
    local offset = 0 -- what byte we are currently looking at

    subtree:add(f.type, buffer(offset, 1))
    local cmd = buffer(offset, 1):uint()
    pinfo.cols.info:set(enums.type[cmd])
    offset = offset + 1

    -- magnet versions >=8 use a 2 byte length field. we might have mixed versions across a capture so this approach works better.
    if buffer(offset, 2):le_uint() == buffer(offset + 2):len() then
        subtree:add_le(f.len16, buffer(offset, 2))
        offset = offset + 2
    else -- use old 1 byte length field
        subtree:add(f.len8, buffer(offset, 1))
        offset = offset + 1
    end

    if cmd == 0x01 then ------ Services
        local service_count = buffer(offset, 1):uint()
        subtree:add(f.service_count, buffer(offset, 1))
        offset = offset + 1

        for i = 0, service_count - 1, 1
        do
            local service_len = buffer(offset, 1):uint()
            local subtree_service = subtree:add(magnet_proto, buffer(offset, service_len + 1))
            offset = offset + 1

            local service_id = buffer(offset, 2):le_uint()
            subtree_service:add_le(f.service_id, buffer(offset, 2))
            offset = offset + 2

            subtree_service:add(f.service_flags, buffer(offset, 1))
            offset = offset + 1

            local service_name_len = buffer(offset, 1):uint()
            offset = offset + 1

            local service_name = buffer(offset, service_name_len):string()
            subtree_service:add(f.service_name, buffer(offset, service_name_len))
            offset = offset + service_name_len

            subtree_service:add(f.service_option, buffer(offset, 1))
            offset = offset + 1

            subtree_service:set_text("Service: "..service_name.." ("..service_id..")")
            magnet_service_mapping[service_id] = service_name -- add service ID mapping to table
        end
    elseif cmd == 0x02 then -- Services Response
        local service_count = buffer(offset, 1):uint()
        subtree:add(f.service_count, buffer(offset, 1))
        offset = offset + 1

        for i = 0, service_count - 1, 1
        do
            local sid = buffer(offset, 2):le_uint()
            local service_name = magnet_service_mapping[sid] or "unknown!" -- look up service name in table
            subtree:add(magnet_proto, buffer(offset, 2), "Service Name: "..service_name.." ("..sid..")")
            offset = offset + 2
        end
    elseif cmd == 0x03 then -- Service Channel Created
        local cid = buffer(offset, 2):le_uint()
        subtree:add_le(f.cid, buffer(offset, 2))
        offset = offset + 2

        local sid = buffer(offset, 2):le_uint()
        local service_name = magnet_service_mapping[sid] or "unknown!"
        subtree:add(magnet_proto, buffer(offset, 2), "Service Name: "..service_name.." ("..sid..")")
        offset = offset + 2

        -- register dissector for channel if service is known and implemented
        assign_l2c_dissector(cid, service_to_dissector[service_name])
    elseif cmd == 0x04 then -- Service Channel Accepted
        subtree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        local sid = buffer(offset, 2):le_uint()
        local service_name = magnet_service_mapping[sid] or "unknown!"
        subtree:add(magnet_proto, buffer(offset, 2), "Service Name: "..service_name.." ("..sid..")")
        offset = offset + 2

        local cid = buffer(offset, 2):le_uint()
        subtree:add_le(f.cid, buffer(offset, 2))
        offset = offset + 2

        -- register dissector for channel if service is known and implemented
        assign_l2c_dissector(cid, service_to_dissector[service_name])
    elseif cmd == 0x05 then -- Service Added
        local service_id = buffer(offset, 2):le_uint()
        subtree:add_le(f.service_id, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 1)) -- unknown byte
        offset = offset + 1

        local service_name_len = buffer(offset, 1):uint()
        offset = offset + 1

        local service_name = buffer(offset, service_name_len):string()
        subtree:add(f.service_name, buffer(offset, service_name_len))
        offset = offset + service_name_len

        subtree:add(f.service_option, buffer(offset, 1))
        offset = offset + 1

        magnet_service_mapping[service_id] = service_name
    elseif cmd == 0x06 then -- Service Removed
        subtree:add_le(f.service_id, buffer(offset, 2))
        offset = offset + 2
    elseif cmd == 0x07 then -- Service Removed Acknowledgement
        subtree:add_le(f.service_id, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1
    elseif cmd == 0x08 then -- Error Response
        subtree:add(f.unknown, buffer(offset))
        offset = offset + buffer(offset):len()
    elseif cmd == 0x09 then -- Version Info
        subtree:add(f.version, buffer(offset, 1))
        offset = offset + 1

        subtree:add(f.flags, buffer(offset, 4))
        offset = offset + 4
    elseif cmd == 0x70 then -- Time Request
    elseif cmd == 0x71 then -- Time Response (type 1)
        local ts = buffer(offset, 8):le_uint64()
        local secs = math.floor(ts:tonumber() / 1e9)
        local nsecs= ts:tonumber() % 1e9
        subtree:add(f.timestamp, buffer(offset, 8), NSTime.new(secs, nsecs)):prepend_text("NSTime ")
        offset = offset + 8

        subtree:add_le(f.unknown, buffer(offset, 8)) -- relative time/uptime?
        offset = offset + 8

        subtree:add(f.unknown, buffer(offset))
        offset = offset + buffer(offset):len()
    elseif cmd == 0x72 then -- Time Response (type 2)
        subtree:add_le(f.unknown, buffer(offset, 8)) -- relative time/uptime?
        offset = offset + 8

        subtree:add_le(f.unknown, buffer(offset))
        offset = offset + buffer(offset):len()
    elseif cmd == 0x90 then -- Device Identification Info
        subtree:add_le(f.vid, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.pid, buffer(offset, 2))
        offset = offset + 2

        subtree:add_le(f.did_version, buffer(offset, 2))
        offset = offset + 2

        -- The chipset field does not exist on Magnet version 7
        if buffer(offset):len() == 2 then
            local chipset_id = buffer(offset, 2):le_uint()
            subtree:add_le(f.chipset, buffer(offset, 2))
            offset = offset + 2
        end
    elseif cmd == 0x91 then -- CoreLocation Durian Command
        if Dissector.get("cldurian") ~= nil then
            Dissector.get("cldurian"):call(buffer(offset):tvb(), pinfo, tree)
        end
    end

    if buffer(offset):len() ~= 0 then -- trailing data
        tree:add(f.unknown, buffer(offset))
    end

    return offset
end

function assign_l2c_dissector(cid, service) -- call dissector by service name to given L2CAP channel ID
    if service ~= nil and Dissector.get(service) ~= nil then
        DissectorTable.get("btl2cap.cid"):add(cid, Dissector.get(service))
    end
end

local channel_id = DissectorTable.get("btl2cap.cid")
channel_id:add(0x3a, magnet_proto)
