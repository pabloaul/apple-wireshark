enums = require("aacp_enums")

local parse =  {} -- init module table

function parse.msg(buffer, pinfo, tree, f)
    local offset = 0

    local type = buffer(offset, 1):uint()
    pinfo.cols.info:append(", " .. (enums.control_type[type] or "Unknown Control"))
    tree:set_text(enums.control_type[type] or "Unknown Control")
    tree:add(f.control_type, buffer(offset, 1))
    offset = offset + 1

    if type == 0x0D then -- Listen Mode
        local mode = buffer(offset, 1):uint()
        tree:add(aacp_proto, buffer(offset, 1), enums.listen_mode[mode])
        offset = offset + 1
    end

    return offset
end

return parse -- return the module table
