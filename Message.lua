setfenv(1, POC)

local msgstack = {}
-- Hide toggle called by the menu or xml button
function HandleMessageBox()
    MessageBoxTitle:SetText('')
    MessageBoxAbout:SetText('')
    MessageBoxText:SetText('')
    MessageBox:SetHidden(true)
    if #msgstack > 0 then
	local args = table.remove(msgstack, 1)
	Message(unpack(args))
    end
end

-- Called on initialize
function Message(about, ...)
    if not MessageBox:IsHidden() then
	msgstack[#msgstack + 1] = {about, ...}
    else
	local message = table.concat({...}, "\n")
	message = string.gsub(message, "%[%*%]", "|t12:12:EsoUI/Art/Miscellaneous/bullet.dds|t")
	MessageBoxTitle:SetText('Message from Piece of Candy addon')
	MessageBoxAbout:SetText('|cffff00' .. about .. '|r')
	MessageBoxText:SetText(message)
	MessageBox:SetHidden(false)
    end
end
