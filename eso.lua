LGS={} LGS.__index = LGS setmetatable(LGS, LGS) function GetUnitName(x) end 
EVENT_MANAGER = {} function EVENT_MANAGER:RegisterForEvent() end function LibStub(x, y) return true end function GetUnitClass(x) end function GetUnitName(x) end function LibStub() return {} end
LGS = {
    saveData = 0
}
LGS.__index = LGS
function LibStub(x)
    return LGS
end
function LGS:RegisterHandler(x, y)
    return {}
end
POC = {} POC.__index = POC

function ZO_CreateStringId(x)
    return
end

function SafeAddVersion(x, y)
    return
end
