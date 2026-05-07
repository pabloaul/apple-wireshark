local enums = require("aacp_enums")
local f = require("aacp_fields")

local parse =  {} -- init module table

function parse.msg(buffer, pinfo, tree)
    local offset = 0

    local type = buffer(offset, 1):uint()
    pinfo.cols.info:append(", " .. (enums.control_type[type] or "Unknown Control"))
    tree:set_text(enums.control_type[type] or "Unknown Control")
    tree:add(f.control_type, buffer(offset, 1))
    offset = offset + 1

    if type == 0x01 then -- Mic Mode
        tree:add(f.mic_mode, buffer(offset, 1))
    elseif type == 0x06 then -- Ownership State
    elseif type == 0x0B then -- Jitter Buffer
        tree:add(f.jitter_buffer, buffer(offset, 1))
    elseif type == 0x0D then -- Listen Mode
        tree:add(f.listen_mode, buffer(offset, 1))
    elseif type == 0x1A then -- Listen Mode Configs
        tree:add(f.listen_mode_configs, buffer(offset, 1))
    elseif type == 0x1C then -- Crown Rotation
        tree:add(f.crown_rotation, buffer(offset, 1))
    elseif type == 0x16 then -- Clock and Hold
        -- two bytes
    elseif type == 0x17 then -- Double Click Interval
    elseif type == 0x18 then -- Click and Hold Interval
    elseif type == 0x1F then -- Chime Volume
        tree:add(f.chime_volume, buffer(offset + 0, 1))
        tree:add(f.chime_volume, buffer(offset + 1, 1))
    elseif type == 0x23 then -- Volume Swipe Interval
    elseif type == 0x24 then -- Call Management Config
        -- three bytes
    elseif type == 0x25 then -- Volume Swipe Mode
    elseif type == 0x2C then -- Hearing Aid
        tree:add(f.feature_control, buffer(offset + 0, 1))
        tree:add(f.feature_control, buffer(offset + 1, 1))
    elseif type == 0x2E then -- AutoANC Strength
        tree:add(f.autoanc_strength, buffer(offset, 1))
    elseif type == 0x38 then -- PPE Cap Level
        tree:add(f.ppe_cap_level, buffer(offset, 1))
    else
        tree:add(f.feature_control, buffer(offset, 1))
    end

    offset = offset + 4
    return offset
end


return parse -- return the module table
