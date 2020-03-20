-- This file provides the functionality for accessing the banned models
-- menu. It is used locally to determine if a model is viable (aka
-- whether or not it gets an outline when moused over).


GM.BannedModels = {} -- This is used as a hash table where the key is the model string and the value is true.
local menu


function GM:IsModelBanned(model)
	return self.BannedModels[model] == true
end


function GM:AddBannedModel(model)
	if self.BannedModels[model] == true then return end -- Prevent duplicates.

	self.BannedModels[model] = true
	menu.AddModel(model)
end


function GM:RemoveBannedModel(model)
	if self.BannedModels[model] != true then return end -- Check if exists before trying to remove.

	self.BannedModels[model] = nil
	menu.RemoveModel(model)
end


net.Receive("ph_bannedmodels_getall", function (len)
	GAMEMODE.BannedModels = {}

	local banned_model = net.ReadString()
	while banned_model != "" do
		GAMEMODE:AddBannedModel(banned_model)
		banned_model = net.ReadString()
	end
end)


net.Receive("ph_bannedmodels_add", function (len)
	local v = net.ReadString()
	GAMEMODE:AddBannedModel(v)
end)


net.Receive("ph_bannedmodels_remove", function (len)
	local v = net.ReadString()
	GAMEMODE:RemoveBannedModel(v)
end)


concommand.Add("ph_bannedmodels_menu", function (client)
	menu:SetVisible(true)
end)


-- This is all the code to create the banned models menu.
-- TODO: I don't like adding this to GM. I feel like there should absolutely be a better solution.
function GM:CreateBannedModelsMenu()
	-- The main window that will contain all of the functionality for display, adding, and
	-- removing banned models.
	menu = vgui.Create("DFrame")
	menu:SetPos(200, 200)
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

	-- What to do when the ENTER key is pressed on the text box.
	function entry:OnEnter()
		-- This client side check is for informational purposes.
		if !LocalPlayer():IsAdmin() then
			chat.AddText(Color(255, 50, 50), "You must be an admin to edit the banned models list.")
			return
		end

		local model_to_ban = entry:GetText()
		-- This client side check is for informational purposes.
		if string.len(model_to_ban) == 0 then
			chat.AddText(Color(255, 50, 50), "Error when attempting to ban model: no input text was given.")
			return
		end
		-- This client side check is for informational purposes.
		if GAMEMODE:IsModelBanned(model_to_ban) then
			chat.AddText(Color(255, 50, 50), "That model is already banned.")
			return
		end

		net.Start("ph_bannedmodels_add")
		net.WriteString(model_to_ban)
		net.SendToServer()
		entry:SetText("")
	end

	-- Makes a scroll bar on the right side in the event that there are a LOT of
	-- banned models and we need to be able to scroll. Will not appear unless
	-- there are enough items in the list to require it.
	local scroll_panel = vgui.Create("DScrollPanel", menu)
	scroll_panel:Dock(FILL)
	
	local model_icon_width = 128
	local model_icon_height = 128
	local usable_width_for_model_icons = menu:GetWide() - scroll_panel:GetVBar():GetWide() -- Don't want icons to overlap the scroll bar.
	local num_cols = math.floor(usable_width_for_model_icons / model_icon_width)
	-- This offset is almost right, but there's 10 pixels more on the left than on the right and I can't figure out why. :(
	local left_offset = (usable_width_for_model_icons - (model_icon_width * num_cols)) / 2

	-- This is the grid that will give the icons a nice layout.
	local grid = vgui.Create("DGrid", scroll_panel)
	menu.grid = grid
	grid:SetCols(num_cols)
	grid:SetPos(left_offset, 10)
	grid:SetColWide(model_icon_width)
	grid:SetRowHeight(model_icon_height)

	-- Allows functions outside of the menu to update the icons. Useful for updating the menu
	-- live if it's open when a net message is received to add a model.
	menu.AddModel = function(model)
		local model_icon = vgui.Create("SpawnIcon")
		model_icon:SetPos(75, 75)
		model_icon:SetSize(model_icon_width, model_icon_height)
		model_icon:SetEnabled(false)
		model_icon:SetCursor("arrow")
		model_icon:SetModel(model)
		grid:AddItem(model_icon)

		local unban_button = vgui.Create("DButton", model_icon)
		unban_button:SetSize(model_icon_width, model_icon_height / 4)
		unban_button:SetText("Unban Model")
		unban_button:SetPos(0, model_icon_height - unban_button:GetTall())
		unban_button:SetVisible(false)

		-- What to do when the unban button for a model is clicked.
		function unban_button:DoClick()
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
		function model_icon:Think()
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
