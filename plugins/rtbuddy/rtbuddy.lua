rtbuddy_proto = Proto("rtbuddy", "Apple RTBuddy")

local descriptors = {
    [0x00000001] = "Acoustic",
    [0x00000002] = "SCP",
    [0x00000004] = "Buddy",
    [0x00000008] = "VirtualCLIPrimary",

    [0x00000010] = "VirtualCLISecondary",
    [0x00000020] = "AppDiagnostics",
    [0x00000040] = "LoggingTrigger",
    [0x00000080] = "DebugData",

    [0x00000100] = "Touch",
    [0x00000200] = "LogConfig", -- (In Ear Status?) handleBTAccessoryGetInEarStatusMsg -- primary in case, secondary in case, IED enabled: yes
    [0x00000400] = "LogMsg", -- airpods to ios
    [0x00000800] = "Sensor", -- (Module Power Message?) / kCBMsgIdLocalDeviceGetModulePowerMsg

    [0x00001000] = "SwitchControl",
    [0x00002000] = "MismatchedBuds",
    [0x00004000] = "?",
    [0x00008000] = "B2P",

    [0x00010000] = "Continuity",
    [0x00020000] = "BatteryHealth",
    [0x00040000] = "SensorV2",
    [0x00080000] = "OBCv2", -- Connected Services?

    [0x00100000] = "Sensor Data WX",
    [0x00200000] = "?",
    [0x00400000] = "?",
    [0x00800000] = "DigitalEngravingInfo",

    [0x01000000] = "ActiveModeData",
}

local f = rtbuddy_proto.fields
    f.descriptor = ProtoField.uint32("rtbuddy.descriptor", "Descriptor", base.HEX, descriptors)
    f.length = ProtoField.uint16("rtbuddy.length", "Length", base.DEC)
    f.plist = ProtoField.string("rtbuddy.plist", "Property List", base.UNICODE)

    f.weird_metric = ProtoField.int16("rtbuddy.weird_metric", "Weird Metric")
    f.unknown = ProtoField.bytes("rtbuddy.data", "Unknown Data", base.NONE)

    f.setting_unknown = ProtoField.uint8("rtbuddy.setting.unknown", "Unknown", base.HEX)
    f.setting_interval = ProtoField.uint32("rtbuddy.setting.interval", "Sample Interval (us)", base.DEC)

    f.motion_type = ProtoField.uint8("rtbuddy.devmotion6.type", "Type", base.HEX)
    f.motion_timestamp = ProtoField.uint64("rtbuddy.devmotion6.timestamp", "Timestamp (ns)", base.DEC)
    f.motion_counter = ProtoField.uint32("rtbuddy.devmotion6.counter", "Counter (5 ms ticks)", base.DEC) -- +8 per sample at 25 Hz, +2 at 100 Hz

-- the meaning of each group was inferred by nodding, shaking and tilting the head (AirPods Pro 3)
local motion_groups = {
    { offset = 20, key = "attitude",     name = "Attitude" },                         -- steady at rest, length ~28000; zero in the first samples after a start
    { offset = 26, key = "rotation",     name = "Rotation Rate" },                    -- ~0 at rest, large on nods and head turns
    { offset = 38, key = "acceleration", name = "User Acceleration" },                -- gravity removed, ~0 at rest
    { offset = 44, key = "gravity",      name = "Gravity" },                          -- ~1024 per g, follows head tilt
}
for _, group in ipairs(motion_groups) do
    group.axes = {}
    for _, axis in ipairs({ "x", "y", "z" }) do
        local field = ProtoField.int16("rtbuddy.devmotion6." .. group.key .. "." .. axis, axis:upper())
        f["motion_" .. group.key .. "_" .. axis] = field
        table.insert(group.axes, field)
    end
end

-- the protobuf dissector hands the payload/configuration bytes to the subdissectors below
-- without their sibling fields, so the services are found by a minimal walk over the message
-- and queued in pinfo.private, in field order. one message can carry several cmd fields
-- (up to 5 motion samples at 100 Hz).
local function read_varint(buffer, offset)
    local value, mult = 0, 1
    while offset < buffer:len() do
        local b = buffer(offset, 1):uint()
        offset = offset + 1
        value = value + (b % 128) * mult
        if b < 128 then return value, offset end
        mult = mult * 128
    end
    return nil, offset
end

-- calls visit(field, value) for varints and visit(field, nil, tvb) for length-delimited fields
local function walk(buffer, visit)
    local offset = 0
    while offset < buffer:len() do
        local tag
        tag, offset = read_varint(buffer, offset)
        if not tag then return end
        local field, wire = math.floor(tag / 8), tag % 8
        if wire == 0 then
            local value
            value, offset = read_varint(buffer, offset)
            if not value then return end
            visit(field, value)
        elseif wire == 1 then
            offset = offset + 8
        elseif wire == 5 then
            offset = offset + 4
        elseif wire == 2 then
            local len
            len, offset = read_varint(buffer, offset)
            if not len or offset + len > buffer:len() then return end
            if len > 0 then visit(field, nil, buffer(offset, len):tvb()) end
            offset = offset + len
        else
            return
        end
    end
end

-- services of the cmd (7) and service_settings (8) messages that carry bytes in field 3
local function find_services(buffer)
    local services = {}
    walk(buffer, function(field, _, inner)
        if (field == 7 or field == 8) and inner then
            local service, has_bytes = "?", false
            walk(inner, function(inner_field, value)
                if inner_field == 1 and value then service = tostring(value) end
                if inner_field == 3 and not value then has_bytes = true end
            end)
            if has_bytes then table.insert(services, service) end
        end
    end)
    return table.concat(services, ",")
end

local function next_service(pinfo)
    local queue = pinfo.private["rtbuddy_services"] or ""
    local head, rest = queue:match("^([^,]*),?(.*)$")
    pinfo.private["rtbuddy_services"] = rest
    return head
end

local SERVICE_DEVMOTION6 = 16

-- ServiceSetting.configuration: 01, then the sample interval in microseconds. an interval of 0 stops the stream.
-- seen with ACTIVITY (14) and DEVMOTION6 (16); the interval is honoured down to ~10000 us (about 100 Hz).
local rtbuddy_setting_proto = Proto("rtbuddy_setting", "Apple RTBuddy Service Setting")

function rtbuddy_setting_proto.dissector(buffer, pinfo, tree)
    next_service(pinfo) -- keep the queue in step with the cmd payloads
    if buffer:len() ~= 5 then
        tree:add(f.unknown, buffer())
        return buffer:len()
    end

    local subtree = tree:add(rtbuddy_setting_proto, buffer(), "Service Setting")
    subtree:add(f.setting_unknown, buffer(0, 1))

    local interval = buffer(1, 4):le_uint()
    local item = subtree:add_le(f.setting_interval, buffer(1, 4))
    if interval == 0 then
        item:append_text(" (stop)")
        pinfo.cols.info:append(" (stop)")
    else
        local rate = string.format("%g Hz", 1e6 / interval)
        item:append_text(" (" .. rate .. ")")
        pinfo.cols.info:append(" (" .. rate .. ")")
    end

    return 5
end

-- Command.payload of DEVMOTION6 (16): one 58 byte motion sample.
-- the stream only starts once ACTIVITY (14) has been requested at least once.
local rtbuddy_devmotion6_proto = Proto("rtbuddy_devmotion6", "Apple RTBuddy Device Motion")

function rtbuddy_devmotion6_proto.dissector(buffer, pinfo, tree)
    -- other services: keep the raw bytes, as the protobuf dissector would without this subdissector
    if next_service(pinfo) ~= tostring(SERVICE_DEVMOTION6) or buffer:len() ~= 58 or buffer(0, 1):uint() ~= 0x01 then
        tree:add(f.unknown, buffer())
        return buffer:len()
    end

    local subtree = tree:add(rtbuddy_devmotion6_proto, buffer(), "Device Motion Sample")
    subtree:add(f.motion_type, buffer(0, 1))
    subtree:add_le(f.motion_timestamp, buffer(1, 8))
    subtree:add(f.unknown, buffer(9, 11))

    for _, group in ipairs(motion_groups) do
        local values = {}
        for i = 0, 2 do table.insert(values, buffer(group.offset + i * 2, 2):le_int()) end
        local group_tree = subtree:add(rtbuddy_devmotion6_proto, buffer(group.offset, 6), group.name .. ": " .. table.concat(values, ", "))
        for i, field in ipairs(group.axes) do
            group_tree:add_le(field, buffer(group.offset + (i - 1) * 2, 2))
        end
        if group.key == "rotation" then
            subtree:add(f.unknown, buffer(32, 6))
        end
    end

    subtree:add(f.unknown, buffer(50, 4))
    subtree:add_le(f.motion_counter, buffer(54, 4))

    pinfo.cols.info:append(" (motion sample)")
    return 58
end

local protobuf_field = DissectorTable.get("protobuf_field")
protobuf_field:add("rtbuddy.ServiceSetting.configuration", rtbuddy_setting_proto)
protobuf_field:add("rtbuddy.Command.payload", rtbuddy_devmotion6_proto)

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

    if descriptor == 0x00000800 then -- Sensor
        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        subtree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4

        subtree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        if buffer(offset):len() ~= 0 then
            subtree:add(f.plist, buffer(offset))
            offset = offset + buffer(offset):len()
        end
    elseif descriptor == 0x00100000 then -- SensorDataWX
        pinfo.private["pb_msg_type"] = "message,rtbuddy.SensorDataWX"

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

        pinfo.private["rtbuddy_services"] = find_services(buffer(offset, length):tvb())

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
