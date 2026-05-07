rtbuddy_proto = Proto("rtbuddy", "Apple RTBuddy")

local descriptors = {
    [0x00000200] = "In Ear Status", -- handleBTAccessoryGetInEarStatusMsg -- primary in case, secondary in case, IED enabled: yes
    [0x00000400] = "some HID stuff?", -- airpods to ios
    [0x00000800] = "Module Power Message", -- kCBMsgIdLocalDeviceGetModulePowerMsg
    [0x00040000] = "Sensor Data V2",
    [0x00080000] = "Connected Services?",
    [0x00100000] = "Sensor Data WX",
}

local f = rtbuddy_proto.fields
    f.descriptor = ProtoField.uint32("rtbuddy.descriptor", "Descriptor", base.HEX, descriptors)
    f.length = ProtoField.uint16("rtbuddy.length", "Length", base.DEC)

    f.weird_metric = ProtoField.int16("rtbuddy.weird_metric", "Weird Metric")
    f.unknown = ProtoField.bytes("rtbuddy.data", "Unknown Data", base.NONE)

function rtbuddy_proto.dissector(buffer, pinfo, tree)
    if buffer():len() == 0 then return end
    pinfo.cols.protocol = rtbuddy_proto.name

    local subtree = tree:add(rtbuddy_proto, buffer(), "Apple RTBuddy")
    local offset = 0

    local descriptor = buffer(offset, 4):le_uint()
    subtree:add_le(f.descriptor, buffer(offset, 4))
    offset = offset + 4

    local length = buffer(offset, 2):le_uint()
    subtree:add_le(f.length, buffer(offset, 2))
    offset = offset + 2

    if descriptor == 0x00100000 then -- SensorDataWX
        pinfo.private["pb_msg_type"] = "message,buddy.SensorDataWX"

        -- HACK: we need to strip the last two bytes if bit 0x4 is set in logtype.
        -- it's kind of a chicken and egg problem because we would have to parse the protobuf
        -- to even know the type but doing so would fail because of the leading two bytes...
        -- what were the apple devs cooking here
        local hack = (
            length > 6 and (buffer(offset+2, 2):uint() == 0x1005 or buffer(offset+3, 2):uint() == 0x1005 or buffer(offset+4, 2):uint() == 0x1005) or
            length > 6 and (buffer(offset+2, 2):uint() == 0x1007 or buffer(offset+3, 2):uint() == 0x1007 or buffer(offset+4, 2):uint() == 0x1007)
        )
        if length > 6 and hack then
            length = length - 2
        end

        Dissector.get("protobuf"):call(buffer(offset, length):tvb(), pinfo, tree)
        offset = offset + length

        if hack then
            tree:add_le(f.unknown, buffer(offset, 2))
            offset = offset + 2
        end
    else
        subtree:add(f.unknown, buffer(offset))
        offset = offset + buffer(offset):len()
    end

    return offset
end
