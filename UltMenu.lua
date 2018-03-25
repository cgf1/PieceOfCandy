setfenv(1, POC)
local collectgarbage = collectgarbage
local GetUnitName = GetUnitName

local LAM = LibStub("LibAddonMenu-2.0")
UltMenu = {}
UltMenu.__index = UltMenu

local okimg = '/POC/icons/ok.dds'
local ok1img = '/POC/icons/ok1.dds'
local nook1img = '/POC/icons/nook1.dds'
local lams = {}
local container
local dropdown
local curapid
local curid
local showicons
local switch

local myults
local ultix = GetUnitName("player")

-- Select ultimate group menu
--
local function set_ult(iconstr)
    dropdown:SetHidden(true)
    if iconstr == switch then
	Ult.SetSavedId()
    elseif iconstr == okimg then
	Ult.SetSavedId(curapid, 1)
    elseif iconstr == ok1img then
	Ult.SetSavedId(curapid, 2)
    elseif iconstr == nook1img then
	Ult.SetSavedId('MIA', 2)
    else
	Swimlanes.SetLaneUlt(curapid, iconstr)
    end
    Swimlanes.Sched()
    collectgarbage("collect")
end

local function get_ult()
    local ult = Ult.ByPing(curapid)
    return ult.Icon
end

-- Show an appropriate "menu" for selecting ultimates
-- 1 = On non-selected: Show primary/secondary
-- 2 = On primary: Show secondary with "switch note"
-- 3 = On secondary: Show secondary with red circle
function UltMenu.ShowUltMenu(parent, id, apid)
    curid = id
    curapid = apid
    if parent.data == nil then
	parent.data = {}
    end

    local n
    if apid ~= myults[1] and apid ~= myults[2] then
	n = 1
    elseif apid == myults[1] then
	n = 2
    elseif myults[2] == 'MIA' then
	n = 3
    else
	n = 4
    end
    if lams[n] == nil then
	local icons = {}
	local tooltips = {}
	local switch
	if n == 1 then
	    icons[#icons + 1] = okimg
	    tooltips[#tooltips + 1] = 'Make this your primary ultimate'
	    icons[#icons + 1] = ok1img
	    tooltips[#tooltips + 1] = 'Make this your secondary ultimate'
	elseif n == 2 then
	    icons[#icons + 1] = ok1img
	    tooltips[#tooltips + 1] = 'Switch primary and secondary ultimates'
	    switch = ok1img
	elseif n == 3 then
	    -- nothing extra
	elseif n == 4 then
	    icons[#icons + 1] = okimg
	    tooltips[#tooltips + 1] = 'Switch primary and secondary ultimates'
	    icons[#icons + 1] = nook1img
	    tooltips[#tooltips + 1] = 'Deselect as your secondary ultimate'
	    switch = okimg
	end

	for i, x in ipairs(Ult.Icons()) do
	    icons[#icons + 1] = x
	end
	for i, x in ipairs(Ult.Descriptions()) do
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
	lams[n] = {
	    [1] = lam,
	    [2] = lam.container,
	    [3] = lam.dropdown,
	    [4] = lam.dropdown:GetHandler("OnMouseUp"),
	    [5] = switch
	}
    end
    lam, container, dropdown, showicons, switch = unpack(lams[n])
    dropdown:SetParent(parent)
    dropdown:ClearAnchors()
    container:SetAnchor(BOTTOMRIGHT, parent, BOTTOMRIGHT, 4, -4)
    dropdown:SetHidden(true)
    lam:UpdateChoices()
    showicons()
end

-- Initialize UltMenu
--
function UltMenu.Initialize()
    myults = Settings.SavedVariables.MyUltId[ultix]
    CALLBACK_MANAGER:RegisterCallback(SHOW_ULTIMATE_GROUP_MENU, UltMenu.ShowUltMenu)
end
