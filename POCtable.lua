local x = {
    __index = _G,
    CompactSwimlaneControl = POC_CompactSwimlaneControl,
    CountdownNumber = POC_CountdownNumber,
    COUNTDOWN_KEY = POC_COUNTDOWN_KEY,
    SwimlaneControl = POC_SwimlaneControl,
    UltNumber = POC_UltNumber,
    UltNumberLabel = POC_UltNumberLabel
}

POC = setmetatable(x, x)
POC.POC = POC
