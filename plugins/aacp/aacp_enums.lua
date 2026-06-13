local e =  {} -- init module table

e.type = {
    [0x00] = "Connect",
    [0x01] = "Connect Response",
    [0x02] = "Disconnect",
    [0x03] = "Disconnect Response",
    [0x04] = "Message",
}

--- AACP Message Enums:
e.message_type = {
    [0x01] = "Capabilities Request",
    [0x02] = "Capabilities",
    [0x03] = "Battery Info Request",
    [0x04] = "Battery Info",
    [0x05] = "Ear Detection Request",
    [0x06] = "Ear Detection",
    [0x07] = "Bud Role Request",
    [0x08] = "Bud Role",
    [0x09] = "Control",
    [0x0B] = "Device List",
    [0x0C] = "MAC Address",
    [0x0D] = "Audio Source Request",
    [0x0E] = "Audio Source",
    [0x0F] = "Set Notification Filter",
    [0x10] = "Smart Routing",
    [0x11] = "Smart Routing",
    [0x12] = "Easy Pair Request",
    [0x13] = "Easy Pair",
    [0x14] = "Connect Priority List",
    [0x15] = "Triangle/Magnet Link Status Request",
    [0x16] = "Triangle/Magnet Link Status",
    [0x17] = "BuddyCommand",
    [0x19] = "Stem Press",
    [0x1A] = "Rename",
    [0x1B] = "Timestamp",
    [0x1D] = "Information",
    [0x1E] = "Send External Accessory Session Packet",
    [0x1F] = "Notify Session State?",
    [0x20] = "Send Remote Firmware Auth Data",
    [0x21] = "Unknown",
    [0x22] = "Case Info Request",
    [0x23] = "Case Info",
    [0x24] = "Send Device Info?",
    [0x26] = "Certificates Request",
    [0x27] = "Certificates",
    [0x28] = "Gyro Info",
    [0x29] = "Set Country Code",
    [0x2B] = "Stream State Info",
    [0x2C] = "GAPA Challenge",
    [0x2D] = "Connected Devices Request",
    [0x2E] = "Connected Devices",
    [0x30] = "Magic Keys Request",
    [0x31] = "Magic Keys",
    [0x32] = "Magic Keys",
    [0x40] = "Unknown",
    [0x44] = "Send Smart Routing 2.0 Info",
    [0x45] = "Fast Connect Complete?",
    [0x47] = "Bud Swap 2.0 Procedure?",
    [0x48] = "Swap Imminent Confirm?",
    [0x49] = "Bud Swap 2.0 Completion?",
    [0x4A] = "Swap Complete Confirm?",
    [0x4B] = "Conversational Awareness", -- aka "Conversation Detect"
    [0x4C] = "Adaptive Volume Message",
    [0x4D] = "Source Feature Capabilities",
    [0x4E] = "Feature ProxCard Status Update",
    [0x4F] = "UARP Data",
    [0x50] = "Unknown", -- PerfStats, begins with subtype?
    [0x52] = "Source Context",
    [0x53] = "Personal Medical Equipment Config",
    [0x54] = "Set Band Edges",
    [0x55] = "Unknown",
    [0x56] = "USB Spatial Sensor Data Request",
    [0x57] = "Sleep Detection Update",
    [0x58] = "Microphone Stream?",
    [0x59] = "Dynamic End Of Charge",
    [0x60] = "Personal Translation",
    [0x62] = "Unknown",
}
-- 0x02 Capabilities
    e.capabilities = {
        [0x01] = "?",
        [0x02] = "?",
        [0x03] = "?",
        [0x04] = "SelectiveSpeechListeningCapability?",
        [0x06] = "EnhancedTransparencyVersion",
        [0x07] = "?",
        [0x09] = "?",
        [0x0a] = "?",
        [0x0b] = "?",
        [0x0f] = "?",
        [0x10] = "?",
        [0x11] = "pmeEverywhereCapability",
        [0x12] = "caseSoundCapability",
        [0x13] = "hideOffListeningModeCapability",
        [0x14] = "?",
        [0x15] = "siriMultitoneCapability",
        [0x16] = "hideEarDetectionCapability",
        [0x17] = "earTipFitTestCapability",
        [0x18] = "autoANCCapability",
        [0x19] = "pauseMediaOnSleep?",
        [0x20] = "wiredLosslessAudioCapability",
        [0x21] = "sleepDetectionCapability",
        [0x22] = "hearingAidCapability",
        [0x23] = "cameraControlCapability",
        [0x24] = "ovadStreamingCapability",
        [0x25] = "farFieldUplinkCapability", -- related to personal translation
        [0x26] = "heartRateMonitorCapable",
        [0x28] = "hearingProtectionPPECapability",
        [0x29] = "dynamicEndOfChargeCapability",
        [0x30] = "hearingProtectionCapability",
        [0x31] = "hearingAidV2Capability",
        [0x34] = "wiredLosslessAudioCapability?",
        [0x35] = "smartRoutingVersion",
        [0x36] = "farFieldUplinkModernCapability", -- related to personal translation
        [0x37] = "preferenceEQCapability",
        [0x38] = "clickHoldExtendedCapabilityFeatureSet",
        [0x40] = "spatialAudioSupport?",
        [0x50] = "callManagementCapability?",
        [0x60] = "?",
        [0x90] = "adaptiveVolumeCapability?",
        [0xa0] = "?",
        [0xb0] = "autoANCCapability?",
        [0xc0] = "hearingAidCapability",
        [0xd0] = "hearingTestCapability",
        [0xe0] = "Sensor Data??", -- something sensordata v2 JB
        [0xf0] = "bobbleCapability",
    }
-- 0x04 Battery Info
    e.battery_component = {
        [0x01] = "Headset/Single",
        [0x02] = "Right",
        [0x04] = "Left",
        [0x08] = "Case",
    }
    e.battery_status = {
        [0x00] = "Unknown",
        [0x01] = "Charging",
        [0x02] = "Discharging",
        [0x04] = "Disconnected",
        [0x05] = "Optimized Charging",
    }
-- 0x06 Ear Detection
    e.bud_location = {
        [0x00] = "In Ear",
        [0x01] = "Out of Ear",
        [0x02] = "In Case",
        [0x03] = "Disconnected",
    }
-- 0x08 Bud Role
    e.bud_role = {
        [0x01] = "Left is primary",
        [0x02] = "Right is primary",
    }
-- 0x0C MAC Address
    e.tipi_variant = {
        [0x01] = "Temporary Address?",
        [0x02] = "Permanent Address?",
    }
    e.tipi_connection_status = {
        [0x01] = "Connected",
        [0x02] = "Disconnected",
        [0x03] = "Not Nearby",
    }
-- 0x0E Audio Source
    e.audio_source_status = {
        [0x00] = "Idle",
        [0x01] = "?",
        [0x02] = "Playing Media",
        [0x04] = "?",
        [0x06] = "?"
    }
-- 0x1D Information
    e.information_string = {
        [0] = "Name",
        [1] = "Model Identifier",
        [2] = "Manufacturer",
        [3] = "Serial Number (System)",
        [4] = "Firmware Version (Active)",
        [5] = "Firmware Version (Pending)",
        [6] = "Hardware Version",
        [7] = "EA Protocol Name",
        [8] = "Serial Number (Left Bud)",
        [9] = "Serial Number (Right Bud)",
        [10] = "Marketing Version",
        [11] = "UUID (Left Bud)",
        [12] = "UUID (Right Bud)",
        [13] = "First Time Pairing (Left Bud)",
        [14] = "First Time Pairing (Right Bud)",
    }
-- 0x31 Magic Keys
    e.mp_key_type = {
        [0x0001] = "magicAccIRK",
        [0x0002] = "?",
        [0x0004] = "magicAccEncKey",
        [0x0008] = "magicAccKey",
        [0x0010] = "magicAccHint",
        [0x0020] = "Nonce",
        [0x0040] = "?",
        [0x0080] = "AES SIV",
        [0x0100] = "magicAccRatchet",
        [0x0200] = "guestAccIRK",
        [0x0400] = "guestAccEncKey",
        [0x1000] = "MasterCloudIRK",
        [0x2000] = "MasterCloudAddress",
    }
-- 0x54 Band Edges
    e.band_code = {
        [0x00] = "ISM 2,4GHz",
        [0x01] = "UNII 1",
        [0x02] = "UNII 3",
        [0x03] = "UNII 4",
        [0x04] = "UNII 5A",
        [0x05] = "UNII 5B",
        [0x06] = "UNII 5C",
        [0x07] = "UNII 5D",
        [0x08] = "Invalid",
    }

--- AACP Control Enums:
e.control_type = {
    [0x01] = "Mic Mode",
    [0x02] = "Scan",
    [0x03] = "Reset",
    [0x04] = "Basic Double Tap Mode",
    [0x05] = "Button Send Mode",
    [0x06] = "Ownership state",
    [0x07] = "Tap Interval",
    [0x08] = "Bud Role",
    [0x09] = "Debug Get Data",
    [0x0A] = "In Ear Detection",
    [0x0B] = "Jitter Buffer", -- aka "Dynamic Latency"
    [0x0C] = "Double Tap Mode",
    [0x0D] = "Listen Mode",
    [0x0E] = "Heart Rate Monitor",
    [0x0F] = "Heart Rate Monitor",
    [0x10] = "Unassigned/Unknown",
    [0x11] = "Switch Control",
    [0x12] = "Voice Trigger",
    [0x13] = "DoAP mode", -- "Dictation over AirPods" for Siri
    [0x14] = "Single Click",
    [0x15] = "Double Click",
    [0x16] = "Click and Hold",
    [0x17] = "Double Click Interval",
    [0x18] = "Click and Hold Interval",
    [0x19] = "Unassigned/Unknown",
    [0x1A] = "Listening Mode Configs",
    [0x1B] = "One Bud ANC Mode",
    [0x1C] = "Crown Rotation Direction",
    [0x1D] = "Unassigned/Unknown",
    [0x1E] = "Auto Answer Mode",
    [0x1F] = "Chime Volume",
    [0x20] = "Smart Routing Mode",
    [0x21] = "Unassigned/Unknown",
    [0x22] = "HFP Uplink Mode", -- HFP probably meaning Hands-Free Profile
    [0x23] = "Volume Swipe Interval",
    [0x24] = "Call Management Config",
    [0x25] = "Volume Swipe Mode",
    [0x26] = "Adaptive Volume",
    [0x27] = "Software Mute",
    [0x28] = "Conversation Detect",
    [0x29] = "Selective Speech Listening",
    [0x2A] = "Unassigned/Unknown",
    [0x2B] = "Unassigned/Unknown",
    [0x2C] = "Hearing Aid",
    [0x2D] = "Unassigned/Unknown",
    [0x2E] = "Auto ANC Strength",
    [0x2F] = "Hearing Aid Gain Swipe",
    [0x30] = "Heart Rate Monitor",
    [0x31] = "In-Case Tone",
    [0x32] = "Siri Multitone",
    [0x33] = "Hearing Assist",
    [0x34] = "Allow Off Option",
    [0x35] = "Sleep Detection",
    [0x36] = "Allow Auto Connect from Audio Accessory",
    [0x37] = "Hearing Protection PPE", -- PPE meaning Personal Protective Equipment
    [0x38] = "PPE Cap Level Config",
    [0x39] = "Raw Gestures Config",
    [0x3A] = "Allow Temporary Managed Pairing",
    [0x3B] = "Dynamic End of Charge",
    [0x3C] = "System Siri Mode",
    [0x3D] = "Hearing Aid Generic", -- "hearingAidV2SourceRegionSupport"
    [0x3E] = "Uplink EQ Bud",
    [0x3F] = "Uplink EQ Source",
    [0x40] = "In Case Tone Volume",
    [0x41] = "Disable Button Input",
    [0x42] = "Extended Hold and Release",
}
e.feature_control = {
    [0x01] = "Enabled",
    [0x02] = "Disabled",
}
-- 0x01 Mic Mode
    e.mic_mode = {
        [0x00] = "Auto",
        [0x01] = "Fixed Right",
        [0x02] = "Fixed Left",
    }
-- 0x0D Listen Mode
    e.listen_mode = {
        [0x01] = "Off",
        [0x02] = "ANC",
        [0x03] = "Transparency",
        [0x04] = "Adaptive",
    }
-- 0x1A Listening Mode Configs
    e.listening_mode_configs = {
        [0x00] = "ANC",
        [0x01] = "Normal/ANC",
        [0x02] = "Transparency",
        [0x03] = "Normal/Transparency",
        [0x04] = "ANC/Transparency",
        [0x05] = "Normal/ANC/Transparency",
        [0x06] = "Auto",
        [0x07] = "Normal/Auto",
        [0x08] = "ANC/Auto",
        [0x09] = "Normal/ANC/Auto",
        [0x0A] = "Transparency/Auto",
        [0x0B] = "Normal/Transparency/Auto",
        [0x0C] = "ANC/Transparency/Auto",
        [0x0D] = "Normal/ANC/Transparency/Auto",
    }
-- 0x1C Crown Rotation Direction
    e.crown_rotation = {
        [0x01] = "Front-to-Back",
        [0x02] = "Back-to-Front",
    }

e.button_mode = {
    [0x00] = "Unknown",
    [0x01] = "Siri",
    [0x02] = "Play/Pause",
    [0x03] = "Next",
    [0x04] = "Previous",
    [0x05] = "ANC",
    [0x06] = "Volume Up",
    [0x07] = "Volume Down",
    [0x7F] = "Off"
}

e.bud_dock_state = {
    [0x01] = "Unknown",
    [0x02] = "Undocked",
    [0x03] = "Docked",
    [0x04] = "Docked Dead",
}

e.bud_lid_state = {
    [0x01] = "Unknown",
    [0x02] = "Closed",
    [0x03] = "Open",
}

return e -- return the module table
