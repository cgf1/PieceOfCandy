-- Local variables
--
POC_UltMenu = {}
POC_UltMenu.__index = POC_UltMenu

local xxx
local okimg = '/POC/icons/ok.dds'
local lam
local container
local dropdown
local curgid
local curid
local showicons

-- Select ultimate group menu
--
local function set_ult(iconstr)
    dropdown:SetHidden(true)
    if iconstr == okimg then
	POC_Ult.SetSavedId(curgid)
    else
	gid = POC_Ult.UltFromIcon(iconstr)
	if gid ~= curgid then
	    CALLBACK_MANAGER:FireCallbacks(POC_SET_ULTIMATE_GROUP, gid, curid)
	end
    end
end

local function get_ult()
    return GetAbilityIcon(curgid)
end

-- Show ultimate group menu
--
--       choices = POC_Ult.Icons(),
--        choicesTooltips = POC_Ult.Descriptions(),
--        getFunc = POC_Ult.GetSaved,
--        setFunc = POC_Ult.SetSaved,
--        maxColumns = 7,
--        visibleRows = 6,
--        iconSize = 40

function POC_UltMenu.ShowUltMenu(parent, id, gid)
    curid = id
    curgid = gid
    if parent.data == nil then
	parent.data = {}
    end
    if dropdown == nil then
	local icons = {[1] = okimg}
	for i, x in ipairs(POC_Ult.Icons()) do
	    icons[#icons + 1] = x
	end
	local tooltips = {[1] = 'Make this your selected ultimate'}
	for i, x in ipairs(POC_Ult.Descriptions()) do
	    tooltips[#tooltips + 1] = x
	end
	lam = LAMCreateControl.iconpicker(parent, {
	    type = "iconpicker",
	    tooltip = "Select ultimate",
	    choices = icons,
	    choicesTooltips = tooltips,
	    getFunc = get_ult,
	    setFunc = set_ult,
	    maxColumns = 7,
	    visibleRows = 5,
	    iconSize = 48,
	})
	container = lam.container
	lam.RealSetHidden = lam.SetHidden
	lam.SetHidden = function () d("HERE") lam:RealSetHidden(true) end
	dropdown = lam.dropdown
	showicons = dropdown:GetHandler("OnMouseUp")
    end
    dropdown:SetParent(parent)
    dropdown:ClearAnchors()
    container:SetAnchor(BOTTOMRIGHT, parent, BOTTOMRIGHT, 4, -4)
    dropdown:SetHidden(true)
    showicons()
end

-- Initialize POC_UltMenu
--
function POC_UltMenu.Initialize()
    xxx = POC.xxx
    CALLBACK_MANAGER:RegisterCallback(POC_SHOW_ULTIMATE_GROUP_MENU, POC_UltMenu.ShowUltMenu)
end
