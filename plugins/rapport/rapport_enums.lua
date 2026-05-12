local e =  {} -- init module table

e.type = {
    [0x00] = "Unknown",
    [0x01] = "NoOp",
    [0x03] = "PS_Start", -- pair-setup start
    [0x04] = "PS_Next", -- pair-setup next
    [0x05] = "PV_Start", -- pair-verify start
    [0x06] = "PV_Next", -- pair-verify next
    [0x07] = "U_OPACK", -- unencrypted opack
    [0x08] = "E_OPACK", -- encrypted opack
    [0x09] = "P_OPACK", -- partial? opack
    [0x0a] = "PA_Req", -- preAuth request
    [0x0b] = "PA_Rsp", -- preAuth response
    [0x10] = "SessionStartRequest",
    [0x11] = "SessionStartResponse",
    [0x12] = "SessionData",
    [0x20] = "FamilyIdentityRequest",
    [0x21] = "FamilyIdentityResponse",
    [0x22] = "FamilyIdentityUpdate",
    [0x30] = "WatchIdentityRequest",
    [0x31] = "WatchIdentityResponse",
    [0x40] = "FriendIdentityRequest",
    [0x41] = "FriendIdentityResponse",
    [0x42] = "FriendIdentityUpdate",
}

return e
