local enums = require("aacp_enums")
local f = aacp_proto.fields

-- AACP:
    f.type = ProtoField.uint16("aacp.type", "Type", base.HEX, enums.type)
    f.service = ProtoField.uint16("aacp.service", "Service", base.DEC)
    f.status = ProtoField.uint16("aacp.status", "Status", base.HEX)
    f.major = ProtoField.uint16("aacp.major", "Major Version", base.DEC)
    f.minor = ProtoField.uint16("aacp.minor", "Minor Version", base.DEC)
    f.features = ProtoField.uint64("aacp.features", "Feature Flags", base.HEX)
-- AACP/Message:
    f.message_type = ProtoField.uint16("aacp.message_type", "Message Type", base.HEX, enums.message_type)
    f.capability = ProtoField.uint8("aacp.capability", "Capability", base.HEX, enums.capabilities)
    f.bud_location = ProtoField.uint8("aacp.bud_location", "Bud Location", base.HEX, enums.bud_location)
    f.bud_role = ProtoField.uint8("aacp.bud_role", "Bud Role", base.HEX, enums.bud_role)
    f.control_type = ProtoField.uint8("aacp.control_type", "Control Type", base.HEX, enums.control_type)
    f.tipi_variant = ProtoField.uint8("aacp.tipi_variant", "TiPi Variant", base.HEX, enums.tipi_variant)
    f.audio_source_status = ProtoField.uint8("aacp.audio_source_status", "Audio Source Status", base.DEC, enums.audio_source_status)
    f.rename_string = ProtoField.string("aacp.rename_string", "Name", base.UNICODE, "String to rename device to")
    f.timestamp = ProtoField.absolute_time("aacp.timestamp", "Unix Timestamp", base.UTC)
    f.timestamp_string = ProtoField.string("aacp.timestamp_string", "String Timestamp", base.ASCII)
-- AACP/Message/MagicPairing:
    f.keytype = ProtoField.uint16("aacp.mp_keytype", "Key Type", base.HEX, enums.mp_key_type)
    f.keylen = ProtoField.uint16("aacp.mp_keylen", "Key Length", base.DEC)
    f.keycount = ProtoField.uint8("aacp.mp_keycount", "Key Count", base.DEC)
    f.key = ProtoField.bytes("aacp.mp_key", "Key", base.NONE)
-- AACP/Message/Control:
    f.feature_control = ProtoField.uint8("aacp.control.feature_control", "Feature", base.HEX, enums.feature_control)
    f.mic_mode = ProtoField.uint8("aacp.control.mic_mode", "Mic Mode", base.DEC, enums.mic_mode)
    f.jitter_buffer = ProtoField.uint8("aacp.control.jitter_buffer", "Jitter Buffer", base.DEC)
    f.listen_mode = ProtoField.uint8("aacp.control.listen_mode", "Listen Mode", base.HEX, enums.listen_mode)
    f.listen_mode_configs = ProtoField.uint8("aacp.control.listen_mode_configs", "Listen Mode Configs", base.HEX, enums.listening_mode_configs)
    f.crown_rotation = ProtoField.uint8("aacp.control.crown_rotation", "Crown Rotation", base.HEX, enums.crown_rotation)
    f.chime_volume = ProtoField.uint8("aacp.control.chime_volume", "Chime Volume", base.DEC)
    f.autoanc_strength = ProtoField.uint8("aacp.control.autoanc_strength", "AutoANC Strength", base.DEC)
    f.ppe_cap_level = ProtoField.uint8("aacp.control.ppe_cap_level", "PPE Cap Level", base.DEC)
-- Misc:
    f.ether = ProtoField.ether("aacp.mac", "MAC Address")
    f.opack_data = ProtoField.protocol("aacp.opack_data", "OPACK Data")
    f.unknown = ProtoField.bytes("aacp.unknown", "Unknown", base.NONE)
    f.unused = ProtoField.bytes("aacp.unused", "Unused", base.NONE)
    f.data = ProtoField.bytes("aacp.data", "Trailing Data", base.NONE)



return f
