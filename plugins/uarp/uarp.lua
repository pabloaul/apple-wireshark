uarp_proto = Proto("uarp", "Apple Unified Accessory Restore Protocol")

local enums = require("uarp_enums")

local f = uarp_proto.fields
    f.type = ProtoField.uint16("uarp.type", "Type", base.HEX, enums.message_type)
    f.length = ProtoField.uint16("uarp.length", "Length", base.DEC)
    f.seq = ProtoField.uint16("uarp.seq", "Sequence", base.DEC)
    f.data = ProtoField.bytes("uarp.data", "Data", base.NONE)
    f.version = ProtoField.uint16("uarp.version", "Version", base.HEX)
    f.status = ProtoField.uint16("uarp.status", "Status", base.HEX, enums.status_code)
    f.fw_apply_status = ProtoField.uint16("uarp.fw_apply_status", "Firmware Application Status", base.HEX, enums.firmware_application_status)
    f.information_property = ProtoField.uint16("uarp.information_property", "Information Property", base.HEX, enums.accessory_property)
    f.asset_id = ProtoField.uint16("uarp.asset_id", "Asset ID", base.DEC)
    f.asset_tag = ProtoField.uint32("uarp.asset_tag", "Asset Tag", base.HEX)
    f.endpoint_id = ProtoField.uint16("uarp.endpoint_id", "Endpoint ID", base.DEC)
    f.data_request_offset = ProtoField.uint32("uarp.data_request_offset", "Data Request Offset", base.HEX)
    f.data_request_length = ProtoField.uint32("uarp.data_request_length", "Data Request Length", base.DEC)
    f.data_actual_length = ProtoField.uint32("uarp.data_actual_length", "Data Actual Length", base.DEC)
    f.asset_format_version = ProtoField.uint32("uarp.asset_format_version", "Asset Format Version?", base.DEC)
    f.asset_version_major = ProtoField.uint32("uarp.asset_version_major", "Asset Version Major", base.DEC)
    f.asset_version_minor = ProtoField.uint32("uarp.asset_version_minor", "Asset Version Minor", base.DEC)
    f.asset_version_release = ProtoField.uint32("uarp.asset_version_release", "Asset Version Release", base.DEC)
    f.asset_version_build = ProtoField.uint32("uarp.asset_version_build", "Asset Version Build", base.DEC)
    f.payload_size = ProtoField.uint32("uarp.payload_size", "Payload Size", base.HEX)
    f.payload_count = ProtoField.uint32("uarp.payload_count", "Payload Count", base.DEC)
    f.unknown = ProtoField.bytes("uarp.unknown", "Unknown", base.NONE)

function uarp_proto.dissector(buffer, pinfo, tree)
    if buffer():len() == 0 then return end
    pinfo.cols.protocol = uarp_proto.name

    local subtree = tree:add(uarp_proto, buffer(), "Apple Unified Accessory Restore Protocol")
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

    if type == 0x00 then -- Sync
    elseif type == 0x01 then -- Version Discovery Request
        subtree:add(f.version, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x02 then -- Version Discovery Response
        subtree:add(f.status, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.version, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x03 then -- Information Request
        subtree:add(f.information_property, buffer(offset, 4))
        offset = offset + 4
    elseif type == 0x04 then -- Information Response
        subtree:add(f.status, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.information_property, buffer(offset, 4))
        offset = offset + 4

        local len = buffer(offset, 4):uint()
        offset = offset + 4

        if len ~= 0 then
            subtree:add(f.data, buffer(offset, len))
            offset = offset + len
        end
    elseif type == 0x05 or type == 0x0D then -- Asset Available Notification (Ack)
        subtree:add(f.asset_tag, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.asset_format_version, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.asset_id, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.asset_version_major, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.asset_version_minor, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.asset_version_release, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.asset_version_build, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.payload_size, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.payload_count, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x06 then -- Data Request
        subtree:add(f.asset_id, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.data_request_offset, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.data_request_length, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x07 then -- Data Response
        subtree:add(f.status, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.asset_id, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.data_request_offset, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.data_request_length, buffer(offset, 2))
        offset = offset + 2

        local len = buffer(offset, 2):uint()
        subtree:add(f.data_actual_length, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.data, buffer(offset, len))
        offset = offset + len
    elseif type == 0x09 then -- Asset Processing Notification
        subtree:add(f.asset_id, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x0A then -- Apply Staged Assets Request
    elseif type == 0x0B then -- Apply Staged Assets Response
        subtree:add(f.fw_apply_status, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x0F then -- Asset Processing Notification Ack
        subtree:add(f.asset_id, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x11 then -- Dynamic Asset Solicitation
        subtree:add(f.asset_tag, buffer(offset, 4))
        offset = offset + 4
    elseif type == 0x12 then -- Dynamic Asset Solicitation Ack
        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.asset_tag, buffer(offset, 4))
        offset = offset + 4
    elseif type == 0x17 then -- Downstream Endpoint Reachable
        subtree:add(f.endpoint_id, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x18 then -- Downstream Endpoint Reachable Ack
        subtree:add(f.status, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.endpoint_id, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x1B then -- Downstream Endpoint Message
        subtree:add(f.endpoint_id, buffer(offset, 2))
        offset = offset + 2

        offset = offset + Dissector.get("uarp"):call(buffer(offset):tvb(), pinfo, tree)
        pinfo.cols.info:prepend("[Downstream] ")
    elseif type == 0x1C then -- Downstream Endpoint Message Ack
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.endpoint_id, buffer(offset, 2))
        offset = offset + 2
    end

    if buffer(offset):len() ~= 0 then
        subtree:add(f.data, buffer(offset))
        offset = offset + buffer(offset):len()
    end

    return offset
end
