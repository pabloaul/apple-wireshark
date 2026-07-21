local enums = require("aacp_enums")
local parse_control = require("aacp_parse_control")
local f = require("aacp_fields")

local parse =  {} -- init module table

function parse.msg(buffer, pinfo, tree)
    local offset = 0

    local type = buffer(offset, 2):le_uint()
    pinfo.cols.info:append(enums.message_type[type] or "Unknown Message")
    tree:set_text(enums.message_type[type] or "Unknown Message")
    tree:add_le(f.message_type, buffer(offset, 2))
    offset = offset + 2

    if type == 0x01 then -- Capabilities Request
        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1
    elseif type == 0x02 then -- Capabilities
        offset = offset + capabilities(buffer(offset), pinfo, tree)
    elseif type == 0x03 then -- Battery Info Request
        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1
    elseif type == 0x04 then -- Battery Info
        local battery_count = buffer(offset, 1):uint()
        offset = offset + 1

        for i = 0, battery_count - 1, 1 do
            local id = buffer(offset, 1):uint()
            local type = buffer(offset + 1, 1):uint()
            local level = buffer(offset + 2, 1):uint()
            local state = buffer(offset + 3, 1):uint()
            local status = buffer(offset + 4, 1):uint()

            tree:add(aacp_proto, buffer(offset, 5), enums.battery_component[id]..": "..level.."% ("..(enums.battery_status[state] or "Unknown")..")")

            offset = offset + 5
        end
    elseif type == 0x06 then -- Ear Detection
        tree:add(f.bud_location, buffer(offset, 1)):prepend_text("Primary ")
        offset = offset + 1

        tree:add(f.bud_location, buffer(offset, 1)):prepend_text("Secondary ")
        offset = offset + 1
    elseif type == 0x08 then -- Bud Role
        tree:add(f.bud_role, buffer(offset, 1))
        offset = offset + 1

        tree:add(f.unknown, buffer(offset, 3))
        offset = offset + 3
    elseif type == 0x09 then -- Control Command
        offset = offset + parse_control.msg(buffer(offset), pinfo, tree)
    elseif type == 0x0C then -- MAC Address
        tree:add_le(f.ether, buffer(offset, 6)) -- TODO: add_le does not actually swap byteorder for f.ether
        offset = offset + 6

        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1
    elseif type == 0x0E then -- Audio Source
        tree:add_le(f.ether, buffer(offset, 6)) -- TODO: add_le does not actually swap byteorder for f.ether
        offset = offset + 6

        tree:add(f.audio_source_status, buffer(offset, 1))
        offset = offset + 1
    elseif type == 0x0F then -- Set Notification Filter
        tree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4
    elseif type == 0x10 or type == 0x11 then -- Smart Routing
        tree:add_le(f.ether, buffer(offset, 6))
        offset = offset + 6

        local len = buffer(offset, 2):le_uint()
        --tree:add_le(aacp_proto, buffer(offset, 2), "Length:", len)
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        tree:add(f.opack_data, buffer(offset, len-1))
        offset = offset + len - 1
    elseif type == 0x12 then -- Easy Pair Request
        tree:add_le(f.ether, buffer(offset, 6)) -- TODO: add_le does not actually swap byteorder for f.ether
        offset = offset + 6

        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        tree:add(f.unknown, buffer(offset, 16))
        offset = offset + 16
    elseif type == 0x13 then -- Easy Pair
        tree:add_le(f.ether, buffer(offset, 6)) -- TODO: add_le does not actually swap byteorder for f.ether
        offset = offset + 6

        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1
    elseif type == 0x14 then -- Connect Priority List
        local count = buffer(offset, 1):uint()
        offset = offset + 1

        for i = 0, count - 1, 1 do
            tree:add_le(f.ether, buffer(offset, 6)) -- TODO: add_le does not actually swap byteorder for f.ether
            offset = offset + 6
        end
    elseif type == 0x15 then -- Triangle/Magnet Link Status Request
        tree:add_le(f.ether, buffer(offset, 6)) -- TODO: add_le does not actually swap byteorder for f.ether
        offset = offset + 6
    elseif type == 0x16 then -- Triangle/Magnet Link Status
        tree:add_le(f.ether, buffer(offset, 6)) -- TODO: add_le does not actually swap byteorder for f.ether
        offset = offset + 6

        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1
    elseif type == 0x1D then -- Information
        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        local length = buffer(offset, 2):le_uint()
        offset = offset + 2

        tree:add_le(f.unknown, buffer(offset, 2))
        offset = offset + 2

        local i = 0
        while offset <= length do
            if (i == 11 or i == 12) then -- UUID fixed length (plus one unknown byte? maybe a character that wraps both uuids)
                tree:add(aacp_proto, buffer(offset, 17), enums.information_string[i] .. ": " ..buffer(offset, 17))
                offset = offset + 17
            else
                local string_len = buffer(offset):strsize(ENC_UTF_8)
                tree:add(aacp_proto, buffer(offset, string_len), enums.information_string[i] .. ": " .. buffer(offset, string_len):string(ENC_UTF_8))
                offset = offset + string_len
            end

            i = i + 1
        end
    elseif type == 0x17 then -- Buddy Command
        offset = offset + Dissector.get("rtbuddy"):call(buffer(offset):tvb(), pinfo, tree)
    elseif type == 0x1A then -- Rename
        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        local name_len = buffer(offset, 2):le_uint()
        offset = offset + 2

        tree:add(f.rename_string, buffer(offset, name_len))
        offset = offset + name_len
    elseif type == 0x1B then -- Timestamp
        tree:add_le(f.timestamp, buffer(offset, 8))
        offset = offset + 8

        local len = buffer(offset, 2):le_uint()
        offset = offset + 2

        tree:add(f.timestamp_string, buffer(offset, len))
        offset = offset + len
    elseif type == 0x1F then -- Notify Session State?
        tree:add(f.unknown, buffer(offset, 5))
        offset = offset + 5
    elseif type == 0x21 then -- Unknown
        tree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        local len = buffer(offset, 2):le_uint()
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x23 then -- Case Info
        -- not sure about alignment yet but it contains the following values:
        -- caseColor 1 byte?
        -- caseVersion
        -- reserved
        -- CaseInfoName
        tree:add(f.unknown, buffer(offset, 1)) -- messageVersion?
        offset = offset + 1

        tree:add_le(f.unknown, buffer(offset, 2)) -- vendorID
        offset = offset + 2

        tree:add_le(f.unknown, buffer(offset, 4)) -- productID (4 bytes for some reason?)
        offset = offset + 4

        tree:add_le(f.unknown, buffer(offset, 2)) -- vendorIDSource
        offset = offset + 2

        tree:add_le(f.unknown, buffer(offset, 4))
        offset = offset + 4

        tree:add_le(f.unknown, buffer(offset, 8))
        offset = offset + 8

        tree:add_le(f.unknown, buffer(offset, 4))
        offset = offset + 4

        tree:add_le(f.unknown, buffer(offset))
        offset = offset + buffer(offset):len()
    elseif type == 0x24 then -- Send Device Info
        tree:add_le(f.unknown, buffer(offset, 5))
        offset = offset + 5
    elseif type == 0x27 then -- Certificates
        tree:add(f.unknown, buffer(offset, 3))
        offset = offset + 3

        local serial_len = buffer(offset, 1):uint()
        offset = offset + 1

        tree:add(aacp_proto, buffer(offset, serial_len), buffer(offset, serial_len):string())
        offset = offset + serial_len

        local data_len = buffer(offset, 2):le_uint()
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, data_len))
        offset = offset + data_len
    elseif type == 0x29 then -- Set Country Code
        tree:add(f.unknown, buffer(offset, 8))
        offset = offset + 8
    elseif type == 0x2B then -- Stream State Info
        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        local len = buffer(offset, 2):le_uint()
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, 8))
        offset = offset + 8

        tree:add_le(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x2C then -- GAPA Challenge
        tree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        local len = buffer(offset, 2):le_uint()
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x2E then -- Connected Devices
        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        local mac_count = buffer(offset, 1):uint()
        offset = offset + 1

        for i = 0, mac_count - 1, 1 do
            local mactree = tree:add(f.ether, buffer(offset, 6))
            offset  = offset + 6

            mactree:add(f.unknown, buffer(offset, 1))
            offset = offset + 1

            mactree:add(f.unknown, buffer(offset, 1))
            offset = offset + 1
        end
    elseif type == 0x30 then -- Magic Keys Request
        tree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x31 then -- Magic Keys
        offset = offset + key_message(buffer(offset), pinfo, tree)
    elseif type == 0x40 then -- Unknown
        tree:add_le(f.unknown, buffer(offset, 2))
        offset = offset + 2

        tree:add_le(f.unknown, buffer(offset, 2))
        offset = offset + 2

        tree:add_le(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x44 then -- Send Smart Routing 2.0 Info
        local len = buffer(offset, 2):le_uint()
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x4B then -- Conversational Awareness
        local len = buffer(offset, 2):le_uint()
        offset = offset + 2

        local subtype = buffer(offset, 1):uint()
        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        tree:add(f.unknown, buffer(offset, len - 1))
        offset = offset + len - 1
    elseif type == 0x4C then -- Adaptive Volume Message
        local len = buffer(offset, 2):le_uint()
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x4E then -- Feature Proximity Card Status
        tree:add(f.unknown, buffer(offset, 8))
        offset = offset + 8
    elseif type == 0x4F then -- UARP
        local len = buffer(offset, 2):le_uint()
        offset = offset + 2

        offset = offset + Dissector.get("uarp"):call(buffer(offset, len):tvb(), pinfo, tree)
    elseif type == 0x52 then -- Source Context
        tree:add(f.unknown, buffer(offset, 5))
        offset = offset + 5
    elseif type == 0x53 then -- PME Config
        local len = buffer(offset, 2):le_uint()
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x54 then -- Band Edges
        local bandCount = buffer(offset, 1):uint()
        offset = offset + 1

        for i = 0, bandCount - 1, 1 do
            local bandIndex = buffer(offset, 1):uint()
            local bandLow = buffer(offset + 1, 1):uint()
            local bandHigh = buffer(offset + 2, 1):uint()

            tree:add_le(aacp_proto, buffer(offset, 3), "Band " .. enums.band_code[bandIndex] .. ": Low " .. bandLow .. " / High " .. bandHigh)
            offset = offset + 3
        end
    elseif type == 0x55 then -- Unknown; almost always after Audio Source. some form of audio state bools?
        tree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4
    elseif type == 0x57 then  -- Sleep Detection Update
        tree:add(f.unknown, buffer(offset, 5))
        offset = offset + 5
    elseif type == 0x58 then -- DoAP Microphone Stream?
        local subtype = buffer(offset, 2):le_uint()
        tree:add_le(f.unknown, buffer(offset, 2), subtype, "subtype:", subtype) -- Type
        offset = offset + 2

        local sublength = buffer(offset, 2):le_uint()
        offset = offset + 2

        if subtype == 0x0001 then
            tree:add_le(f.unknown, buffer(offset, 2), buffer(offset, 2):uint(), "decompressed size:", buffer(offset, 2):uint())
            offset = offset + 2

            local subtype2 = buffer(offset, 2):le_uint()
            tree:add_le(f.unknown, buffer(offset, 2), subtype2, "subtype2:", subtype2) -- Type
            offset = offset + 2

            local sublength2 = buffer(offset, 2):le_uint()
            offset = offset + 2

            if subtype2 == 0x0001 then
                local weird = buffer(offset, 2):le_uint()
                tree:add_le(f.unknown, buffer(offset, 2), weird, "initial time?:", weird)
                offset = offset + 2

                local time1 = buffer(offset, 2):le_uint()
                tree:add_le(f.unknown, buffer(offset, 2), time1, "time (ms):", time1)
                offset = offset + 2

                local weird2 = buffer(offset, 2):le_uint()
                tree:add_le(f.unknown, buffer(offset, 2), weird2, "initial samplecount?:", weird2)
                offset = offset + 2

                local samplecount = buffer(offset, 4):le_uint()
                tree:add_le(f.unknown, buffer(offset, 4), samplecount, "samplecount:", samplecount)
                offset = offset + 4

                tree:add_le(f.unknown, buffer(offset, 2)) -- instantaneous bitrate?
                offset = offset + 2

                offset = offset + Dissector.get("opus"):call(buffer(offset):tvb(), pinfo, tree)
            end

        end
    elseif type == 0x63 then -- EQ
        local len = buffer(offset, 2):le_uint()
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        tree:add(f.eq_state, buffer(offset, 1))
        offset = offset + 1

        tree:add(f.eq_low, buffer(offset, 1))
        offset = offset + 1

        tree:add(f.eq_mid, buffer(offset, 1))
        offset = offset + 1

        tree:add(f.eq_high, buffer(offset, 1))
        offset = offset + 1
    else
    end

    return offset
end

function key_message(buffer, pinfo, tree)
    local offset = 0

    local key_count = buffer(offset, 1):uint()
    tree:add(f.keycount, buffer(offset, 1))
    offset = offset + 1

    for i = 0, key_count - 1, 1 do
        local key = tree:add_le(f.keytype, buffer(offset, 2))
        offset = offset + 2

        local keylen = buffer(offset, 2):le_uint()
        key:add_le(f.keylen, buffer(offset, 2))
        offset = offset + 2

        key:add(f.key, buffer(offset, keylen))
        offset = offset + keylen
    end

    return offset
end

function capabilities(buffer, pinfo, tree)
    local offset = 0

    local capability_count = buffer(offset, 1):uint()
    offset = offset + 1

    for i = 0, capability_count - 1, 1 do
        local cap = buffer(offset, 1):uint()
        local capabilitytree = tree:add(f.capability, buffer(offset, 1))
        offset = offset + 1

        -- capability with 4 byte value length
        if (cap == 0x03 or cap == 0x04 or cap == 0x06 or cap == 0x07 or cap == 0x30) then
            capabilitytree:append_text(": "..buffer(offset, 4):le_uint())
            offset = offset + 4
        else -- capability with 1 byte value length
            capabilitytree:append_text(": "..buffer(offset, 1):uint())
            offset = offset + 1
        end
    end

    return offset
end

return parse -- return the module table
