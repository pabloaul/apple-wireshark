enums = require("aacp_enums")
parse_control = require("aacp_parse_control")

local parse =  {} -- init module table

function parse.msg(buffer, pinfo, tree, f)
    local offset = 0

    local type = buffer(offset, 2):le_uint()
    pinfo.cols.info:append(enums.message_type[type] or "Unknown Message")
    tree:set_text(enums.message_type[type] or "Unknown Message")
    tree:add_le(f.message_type, buffer(offset, 2))
    offset = offset + 2

    if type == 0x01 then -- Capabilities Request
        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1
    elseif type == 0x04 then -- Battery Info
        local battery_count = buffer(offset, 1):uint()
        offset = offset + 1

        for i = 0, battery_count - 1, 1 do
            local component = buffer(offset, 1):uint()
            local chargevol = buffer(offset + 2, 1):uint()
            local status = buffer(offset + 3, 1):uint()

            tree:add(aacp_proto, buffer(offset, 5), enums.battery_component[component]..": "..chargevol.."% ("..(enums.battery_status[status] or "Unknown")..")")

            offset = offset + 5
        end
    elseif type == 0x06 then -- Ear Detection
        local primary = enums.ear_detection[buffer(offset, 1):uint()]
        tree:add(aacp_proto, buffer(offset, 1), "Primary:", primary)
        offset = offset + 1

        local secondary = enums.ear_detection[buffer(offset, 1):uint()]
        tree:add(aacp_proto, buffer(offset, 1), "Secondary:", secondary)
        offset = offset + 1
    elseif type == 0x08 then -- Bud Role
        local role = buffer(offset, 1):uint()
        tree:add(aacp_proto, buffer(offset, 1), enums.bud_role[role])
        offset = offset + 1

        tree:add(f.unknown, buffer(offset, 3))
        offset = offset + 3
    elseif type == 0x09 then -- Control Command
        local control_tree = tree:add(aacp_proto, buffer(offset), "Control")
        offset = offset + parse_control.msg(buffer(offset), pinfo, control_tree, f)
    elseif type == 0x0C then -- MAC Address
        tree:add_le(f.ether, buffer(offset, 6)) -- TODO: add_le does not actually swap byteorder for f.ether
        offset = offset + 6

        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        tree:add(f.tipi_variant, buffer(offset, 1))
        offset = offset + 1
    elseif type == 0x0E then -- Audio Source
        tree:add_le(f.ether, buffer(offset, 6)) -- TODO: add_le does not actually swap byteorder for f.ether
        offset = offset + 6

        tree:add(f.unknown, buffer(offset, 1))
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
        offset = offset + len-1
    elseif type == 0x14 then -- Connect Priority List
        local count = buffer(offset, 1):uint()
        offset = offset + 1

        for i = 0, count-1, 1 do
            tree:add_le(f.ether, buffer(offset, 6)) -- TODO: add_le does not actually swap byteorder for f.ether
            offset = offset + 6
        end
    elseif type == 0x1D then -- Information
        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        local length = buffer(offset, 2):le_uint()
        --tree:add_le(aacp_proto, buffer(offset, 2), "Length:", length)
        offset = offset + 2

        tree:add_le(f.unknown, buffer(offset, 2))
        offset = offset + 2

        local i = 0
        while offset <= length do
            if not (i == 11 or i == 12) then
                local string_len = buffer(offset):strsize(ENC_UTF_8)
                tree:add(aacp_proto, buffer(offset, string_len), enums.information_string[i] .. ": " .. buffer(offset, string_len):string(ENC_UTF_8))
                offset = offset + string_len
            else -- UUID fixed length (plus one unknown byte? maybe a character that wraps both uuids)
                tree:add(aacp_proto, buffer(offset, 17), enums.information_string[i] .. ": " .. buffer(offset, 17))
                offset = offset + 17
            end

            i = i + 1
        end
    elseif type == 0x17 then -- Buddy Command
        -- smells a bit like Protobuf here but can't figure it out yet
        tree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4

        local buddylen = buffer(offset, 2):le_uint()
        tree:add_le(aacp_proto, buffer(offset, 2), "Length:", buddylen)
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, buddylen))
        offset = offset + buddylen
    elseif type == 0x1B then -- Timestamp
        tree:add(f.unknown, buffer(offset, 8)) -- TODO: its probably just NSTime
        offset = offset + 8

        local len = buffer(offset, 2):le_uint()
        -- tree:add_le(aacp_proto, buffer(offset, 2), "Length:", len)
        offset = offset + 2

        tree:add(aacp_proto, buffer(offset, len), buffer(offset, len):string())
        offset = offset + len
    elseif type == 0x21 then -- Unknown
        tree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        local len = buffer(offset, 2):le_uint()
        -- tree:add_le(aacp_proto, buffer(offset, 2), "Length:", len)
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x23 then -- Case Info
        -- not sure about alignment yet but it contains the following values:
        -- messageVersion
        -- vendorID
        -- productID
        -- vendorIDSource
        -- caseColor
        -- caseVersion
        -- reserved
        -- CaseInfoName
        tree:add_le(f.unknown, buffer(offset, 1))
        offset = offset + 1

        tree:add_le(f.unknown, buffer(offset, 2))
        offset = offset + 2

        tree:add_le(f.unknown, buffer(offset, 4))
        offset = offset + 4

        tree:add_le(f.unknown, buffer(offset, 2))
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
        -- tree:add(aacp_proto, buffer(offset, 1), "Serial Length:", serial_len)
        offset = offset + 1

        tree:add(aacp_proto, buffer(offset, serial_len), buffer(offset, serial_len):string())
        offset = offset + serial_len

        local len = buffer(offset, 2):le_uint()
        -- tree:add_le(aacp_proto, buffer(offset, 2), "Length:", len)
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x29 then -- Set Country Code
        tree:add(f.unknown, buffer(offset, 8))
        offset = offset + 8
    elseif type == 0x2B then -- Stream State Info
        tree:add(f.unknown, buffer(offset, 1))
        offset = offset + 1

        local len = buffer(offset, 2):le_uint()
        -- tree:add_le(aacp_proto, buffer(offset, 2), "Length:", len)
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, 8))
        offset = offset + 8

        tree:add_le(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x2C then -- GAPA Challenge
        tree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2

        local len = buffer(offset, 2):le_uint()
        tree:add_le(f.unknown, buffer(offset, 2))
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x2E then -- Connected Devices
        tree:add(f.unknown, buffer(offset, 1)) -- audioStatus?
        offset = offset + 1

        tree:add(f.unknown, buffer(offset, 1)) -- sourceCount?
        offset = offset + 1

        local mac_count = buffer(offset, 1):uint()
        tree:add(aacp_proto, buffer(offset, 1), "TiPi List Count: ", mac_count)
        offset = offset + 1

        for i = 0, mac_count - 1, 1 do
            tree:add_le(f.ether, buffer(offset, 6)) -- big endian mac!
            offset  = offset + 6

            local state = buffer(offset, 1):uint()
            tree:add(aacp_proto, buffer(offset, 1), "connectionStatus:", enums.tipi_connection_status[state])
            offset = offset + 1

            tree:add(aacp_proto, buffer(offset, 1), "stateFlags")
            offset = offset + 1
        end
    elseif type == 0x30 then -- Magic Keys Request
        tree:add(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x31 then -- Magic Keys
        offset = offset + magicpairing_key_message(buffer(offset), pinfo, tree, f)
    elseif type == 0x40 then -- Unknown
        tree:add_le(f.unknown, buffer(offset, 2))
        offset = offset + 2

        tree:add_le(f.unknown, buffer(offset, 2))
        offset = offset + 2

        tree:add_le(f.unknown, buffer(offset, 2))
        offset = offset + 2
    elseif type == 0x44 then -- Send Smart Routing 2.0 Info
        local len = buffer(offset, 2):le_uint()
        --tree:add_le(aacp_proto, buffer(offset, 2), "Length:", len)
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x4B then -- Conversational Awareness
        local len = buffer(offset, 2):le_uint()
        tree:add_le(aacp_proto, buffer(offset, 2), "Length:", len)
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x4C then -- Adaptive Volume Message
        local len = buffer(offset, 2):le_uint()
        tree:add_le(aacp_proto, buffer(offset, 2), "Length:", len)
        offset = offset + 2

        tree:add(f.unknown, buffer(offset, len))
        offset = offset + len
    elseif type == 0x4E then -- Feature Proximity Card Status
        tree:add(f.unknown, buffer(offset, 8))
        offset = offset + 8
    elseif type == 0x4F then -- UARP
        local len = buffer(offset, 2):le_uint()
        offset = offset + 2

        tree:add(f.uarp_data, buffer(offset, len))
        offset = offset + len
    elseif type == 0x53 then -- PME Config
        local len = buffer(offset, 2):le_uint()
        tree:add_le(aacp_proto, buffer(offset, 2), "Length:", len)
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

            tree:add_le(aacp_proto, buffer(offset, 3),
                "Band " .. enums.band_code[bandIndex] .. ": Low " .. bandLow .. " / High " .. bandHigh)
            offset = offset + 3
        end
    elseif type == 0x55 then -- Unknown -- almost always after Audio Source. some form of audio state bools?
        tree:add(f.unknown, buffer(offset, 4))
        offset = offset + 4
    end

    return offset
end


function magicpairing_key_message(buffer, pinfo, tree, f)
    local offset = 0

    local key_count = buffer(offset, 1):uint()
    tree:add(f.keycount, buffer(offset, 1))
    offset = offset + 1

    for i = 0, key_count-1, 1 do
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

return parse -- return the module table
