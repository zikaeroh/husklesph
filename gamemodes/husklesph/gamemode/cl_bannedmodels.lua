-- This file provides the functionality for accessing the banned models
-- menu. It is used locally to determine if a model is viable (aka
-- whether or not it gets an outline when moused over).

GM.BannedModels = {} -- This is used as a hash table where the key is the model string and the value is true.
local menu

function GM:IsModelBanned(model)
	return self.BannedModels[model] == true
end

function GM:AddBannedModel(model)
	if self.BannedModels[model] == true then return end

	self.BannedModels[model] = true
	menu.AddModel(model)
end

function GM:RemoveBannedModel(model)
	if self.BannedModels[model] != true then return end

	self.BannedModels[model] = nil
	menu.RemoveModel(model)
end

net.Receive("ph_bannedmodels_getall", function(len)
	GAMEMODE.BannedModels = {}

	local model = net.ReadString()
	while model != "" do
		GAMEMODE:AddBannedModel(model)
		model = net.ReadString()
	end
end)

net.Receive("ph_bannedmodels_add", function(len)
	local model = net.ReadString()
	GAMEMODE:AddBannedModel(model)
end)

net.Receive("ph_bannedmodels_remove", function(len)
	local model = net.ReadString()
	GAMEMODE:RemoveBannedModel(model)
end)

concommand.Add("ph_bannedmodels_menu", function(client)
	menu:SetVisible(true)
end)

-- This is all the code to create the banned models menu.
function GM:CreateBannedModelsMenu()
	-- The main window that will contain all of the functionality for display, adding, and
	-- removing banned models.
	menu = vgui.Create("DFrame")
	menu:SetSize(ScrW() * 0.4, ScrH() * 0.8)
	menu:SetTitle("Banned Models")
	menu:Center()
	menu:SetDraggable(true)
	menu:ShowCloseButton(true)
	menu:MakePopup()
	menu:SetDeleteOnClose(false)
	menu:SetVisible(false)

	-- Create a text box at the top of the window so the player can input new banned models.
	local entry = vgui.Create("DTextEntry", menu)
	entry:Dock(TOP)
	if LocalPlayer():IsAdmin() then
		entry:SetPlaceholderText("Hover for usage information.")
		entry:SetTooltip([[
			To ban a model from usage put the path
			to the model into this text box and
			press Enter.
			EXAMPLE INPUTS
			models/props/cs_assault/money.mdl
			models/props_borealis/bluebarrel001.mdl
			models/props/cs_office/projector_remote.mdl]])
	else
		entry:SetPlaceholderText("You must be an admin to ban models.")
		entry:SetTooltip("You must be an admin to ban models.")
		entry:SetEnabled(false)
	end

	function entry:OnEnter()
		-- This client side check is for informational purposes.
		if !LocalPlayer():IsAdmin() then
			chat.AddText(Color(255, 50, 50), "You must be an admin to edit the banned models list.")
			return
		end

		local modelToBan = entry:GetText()
		-- This client side check is for informational purposes.
		if modelToBan == "" then
			chat.AddText(Color(255, 50, 50), "Error when attempting to ban model: no input text was given.")
			return
		end
		-- This client side check is for informational purposes.
		if GAMEMODE:IsModelBanned(modelToBan) then
			chat.AddText(Color(255, 50, 50), "That model is already banned.")
			return
		end

		net.Start("ph_bannedmodels_add")
		net.WriteString(modelToBan)
		net.SendToServer()
		entry:SetText("")
	end

	-- Makes a scroll bar on the right side in the event that there are a LOT of
	-- banned models and we need to be able to scroll. Will not appear unless
	-- there are enough items in the list to require it.
	local scrollPanel = vgui.Create("DScrollPanel", menu)
	scrollPanel:Dock(FILL)

	local modelIconWidth = 128
	local modelIconHeight = 128
	local usableWidthForModelIcons = menu:GetWide() - scrollPanel:GetVBar():GetWide() -- Don't want icons to overlap the scroll bar.
	local numCols = math.floor(usableWidthForModelIcons / modelIconWidth)
	-- This offset is almost right, but there's 10 pixels more on the left than on the right and I can't figure out why. :(
	local leftOffset = (usableWidthForModelIcons - (modelIconWidth * numCols)) / 2

	-- This is the grid that will give the icons a nice layout.
	local grid = vgui.Create("DGrid", scrollPanel)
	menu.grid = grid
	grid:SetCols(numCols)
	grid:SetPos(leftOffset, 10)
	grid:SetColWide(modelIconWidth)
	grid:SetRowHeight(modelIconHeight)

	-- Allows functions outside of the menu to update the icons. Useful for updating the menu
	-- live if it's open when a net message is received to add a model.
	menu.AddModel = function(model)
		local modelIcon = vgui.Create("SpawnIcon")
		modelIcon:SetPos(75, 75)
		modelIcon:SetSize(modelIconWidth, modelIconHeight)
		modelIcon:SetEnabled(false)
		modelIcon:SetCursor("arrow")
		modelIcon:SetModel(model)
		grid:AddItem(modelIcon)

		local unbanButton = vgui.Create("DButton", modelIcon)
		unbanButton:SetSize(modelIconWidth, modelIconHeight / 4)
		unbanButton:SetText("Unban Model")
		unbanButton:SetPos(0, modelIconHeight - unbanButton:GetTall())
		unbanButton:SetVisible(false)

		function unbanButton:DoClick()
			-- This client side check is for informational purposes.
			if !LocalPlayer():IsAdmin() then
				chat.AddText(Color(255, 50, 50), "You must be an admin to edit the banned models list.")
				return
			end

			net.Start("ph_bannedmodels_remove")
			net.WriteString(self:GetParent():GetModelName())
			net.SendToServer()
		end

		-- Logic for showing/hiding the unban button.
		function modelIcon:Think()
			self:GetChild(1):SetVisible(LocalPlayer():IsAdmin() && (self:IsHovered() || self:IsChildHovered()))
		end
	end

	-- Same as menu.AddModel but for removing models from the grid.
	menu.RemoveModel = function(model)
		for _, value in pairs(menu.grid:GetItems()) do
			if value:GetModelName() == model then
				menu.grid:RemoveItem(value)
				break
			end
		end
	end
end
