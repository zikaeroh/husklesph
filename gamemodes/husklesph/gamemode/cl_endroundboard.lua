local menu

local function createEndRoundMenu()
	menu = vgui.Create("DFrame")
	menu:SetSize(ScrW() * 0.4, ScrH() * 0.6)
	menu:Center()
	menu:MakePopup()
	menu:SetMouseInputEnabled(true)
	menu:SetKeyboardInputEnabled(false)
	menu:SetDeleteOnClose(false)

	local matBlurScreen = Material("pp/blurscreen")
	function menu:Paint(w, h)
		-- Create a blured background to the entire menu. This makes the content easier
		-- to read against the semi-transparent background.
		local x, y = self:LocalToScreen(0, 0)
		local Fraction = 0.4

		surface.SetMaterial(matBlurScreen)
		surface.SetDrawColor(255, 255, 255, 255)

		for i = 0.33, 1, 0.33 do
			matBlurScreen:SetFloat("$blur", Fraction * 5 * i)
			matBlurScreen:Recompute()
			if render then render.UpdateScreenEffectTexture() end
			surface.DrawTexturedRect(x * -1, y * -1, ScrW(), ScrH())
		end

		-- 2 pixel thick black border on the OUTSIDE of the panel
		-- Temporarily disable clipping so we can draw outside the bounds of menu
		surface.SetDrawColor(0, 0, 0, 230)
		DisableClipping(true)
		surface.DrawOutlinedRect(-1, -1, w + 2, h + 2)
		surface.DrawOutlinedRect(-2, -2, w + 4, h + 4)
		DisableClipping(false)

		-- Title bar rectangle (the title bar is always 22 pixels in height)
		surface.SetDrawColor(40, 40, 40, 230)
		surface.DrawRect(0, 0, w, 22)

		-- Light grey background on lower area
		surface.SetDrawColor(60, 60, 60, 230)
		surface.DrawRect(0, 22, w, h)
	end

	menu.changeTitle = function(newTitle)
		menu:SetTitle(newTitle)
	end

	-- Results section (this is just a container for winner, awards, and resultsTimeLeft)
	local resultsPanel = vgui.Create("DPanel", menu)
	resultsPanel:Dock(FILL)

	function resultsPanel:Paint(w, h) end

	menu.setResultsPanelVisibility = function(isVisible)
		resultsPanel:SetVisible(isVisible)
	end

	-- Text label at the top specifying who won
	local winner = vgui.Create("DLabel", resultsPanel)
	winner:Dock(TOP)
	winner:SetTall(draw.GetFontHeight("RobotoHUD-30"))
	winner:SetFont("RobotoHUD-30")
	winner:SetContentAlignment(5) -- Center

	menu.setWinningTeamText = function(winState)
		if winState == WIN_NONE then
			winner:SetText("Round tied")
			winner:SetColor(Color(150, 150, 150))
		else
			winner:SetText(team.GetName(winState) .. " win!")
			winner:SetColor(team.GetColor(winState))
		end
	end

	-- Middle area where the player awards are listed
	local awards = vgui.Create("DScrollPanel", resultsPanel)
	awards:Dock(FILL)

	function awards:Paint(w, h)
		-- Add a dark rectangle over the area for the awards to visually separate it from rest of the menu
		surface.SetDrawColor(20, 20, 20, 150)
		surface.DrawRect(0, 0, w, h)
	end

	local canvas = awards:GetCanvas()
	canvas:DockPadding(0, 0, 0, 0)

	function canvas:OnChildAdded(child)
		-- Awards fill from top to bottom
		child:Dock(TOP)
		child:DockMargin(10, 10, 10, 0)
	end

	menu.setPlayerAwards = function(allAwards)
		awards:Clear()

		for _, award in pairs(allAwards) do
			local containerPanel = vgui.Create("DPanel")
			containerPanel:SetTall(draw.GetFontHeight("RobotoHUD-20"))

			function containerPanel:Paint(w, h)
				surface.SetDrawColor(50, 50, 50)
				draw.DrawText(award.name, "RobotoHUD-10", 0, 0, Color(220, 220, 220), 0)
				draw.DrawText(award.desc, "RobotoHUD-10", 0, draw.GetFontHeight("RobotoHUD-10"), Color(120, 120, 120), 0)
				draw.DrawText(award.winnerName, "RobotoHUD-15", w, (h / 2) - (draw.GetFontHeight("RobotoHUD-20") / 2), team.GetColor(award.winnerTeam), 2)
			end

			awards:AddItem(containerPanel)
		end
	end

	-- Timer at bottom right showing how long until next round/mapvote
	local resultsTimeLeft = vgui.Create("DPanel", resultsPanel)
	resultsTimeLeft:Dock(BOTTOM)
	resultsTimeLeft:SetTall(draw.GetFontHeight("RobotoHUD-15"))

	function resultsTimeLeft:Paint(w, h)
		-- "Extend" the dark rectangle from awards:Paint to make a larger seamless rectangle
		surface.SetDrawColor(20, 20, 20, 150)
		surface.DrawRect(0, 0, w, h)

		if GAMEMODE:GetGameState() == ROUND_POST then
			local settings = GAMEMODE:GetRoundSettings()
			local roundTime = settings.NextRoundTime || 30
			local time = math.max(0, roundTime - GAMEMODE:GetStateRunningTime())
			-- TODO: Say "Mapvote in..." if last round
			draw.DrawText("Next round in " .. math.ceil(time), "RobotoHUD-15", w - 4, 0, Color(150, 150, 150), 2)
		end
	end

	-- Map vote section (container for mapList and mapVoteTimeLeft)
	local votemapPanel = vgui.Create("DPanel", menu)
	votemapPanel:Dock(FILL)

	function votemapPanel:Paint(w, h) end

	menu.setVotemapPanelVisibility = function(isVisible)
		votemapPanel:SetVisible(isVisible)
	end

	-- List containing map images, map names, and map votes
	local mapList = vgui.Create("DScrollPanel", votemapPanel)
	menu.MapVoteList = mapList
	mapList:Dock(FILL)
	mapList:DockMargin(0, 0, 0, 0)

	function mapList:Paint(w, h)
		surface.SetDrawColor(20, 20, 20, 150)
		surface.DrawRect(0, 0, w, h)
	end

	local canvas = mapList:GetCanvas()
	canvas:DockPadding(20, 0, 20, 0)

	function canvas:OnChildAdded(child)
		child:Dock(TOP)
		child:DockMargin(0, 15, 0, 0)
	end

	-- Text showing time until map vote ends
	local mapVoteTimeLeft = vgui.Create("DPanel", votemapPanel)
	mapVoteTimeLeft:Dock(BOTTOM)
	mapVoteTimeLeft:SetTall(draw.GetFontHeight("RobotoHUD-15"))

	function mapVoteTimeLeft:Paint(w, h)
		surface.SetDrawColor(20, 20, 20, 150)
		surface.DrawRect(0, 0, w, h)

		if GAMEMODE:GetGameState() == ROUND_MAPVOTE then
			local voteTime = GAMEMODE.MapVoteTime || 30
			local time = math.max(0, voteTime - GAMEMODE:GetMapVoteRunningTime())
			draw.SimpleText("Voting ends in " .. math.ceil(time), "RobotoHUD-15", w - 4, 0, Color(150, 150, 150), 2)
		end
	end
end

function GM:EndRoundMenuResults(res)
	self:OpenEndRoundMenu()

	menu.changeTitle("Round Results")
	menu.setResultsPanelVisibility(true)
	menu.setVotemapPanelVisibility(false)
	menu.Results = res
	menu.setPlayerAwards(res.playerAwards)
	menu.setWinningTeamText(res.winningTeam)
end

function GM:EndRoundMapVote()
	self:OpenEndRoundMenu()

	menu.changeTitle("Map Vote")
	menu.setResultsPanelVisibility(false)
	menu.setVotemapPanelVisibility(true)
	menu.MapVoteList:Clear()

	for k, map in pairs(self.MapList) do
		local but = vgui.Create("DButton")
		but:SetText("")
		but:SetTall(128)

		local png
		local path = "maps/" .. map .. ".png"
		if file.Exists(path, "GAME") then
			png = Material(path, "noclamp")
		else
			local path = "maps/thumb/" .. map .. ".png"
			if file.Exists(path, "GAME") then
				png = Material(path, "noclamp")
			else
				local path = "materials/maps/" .. map .. ".png"
				if file.Exists(path, "GAME") then
					png = Material(path, "noclamp")
				end
			end
		end

		local dname = map:gsub("^%a%a%a?_", ""):gsub("_?v[%d%.%-]+$", "")
		dname = dname:gsub("[_]", " "):gsub("([%a])([%a]+)", function(a, b) return a:upper() .. b end)
		local z = tonumber(util.CRC(dname):sub(1, 8))
		local mcol = Color(z % 255, z / 255 % 255, z / 255 / 255 % 255, 50)
		local gray = Color(150, 150, 150)

		but.VotesScroll = 0
		but.VotesScrollDir = 1

		function but:Paint(w, h)
			if self.Hovered then
				surface.SetDrawColor(50, 50, 50, 50)
				surface.DrawRect(0, 0, w, h)
			end

			draw.SimpleText(dname, "RobotoHUD-15", 128 + 20, 20, color_white, 0)
			local fg = draw.GetFontHeight("RobotoHUD-15")
			draw.SimpleText(map, "RobotoHUD-L10", 128 + 20, 20 + fg, gray, 0)
			if png then
				surface.SetMaterial(png)
				surface.SetDrawColor(255, 255, 255, 255)
				surface.DrawTexturedRect(0, 0, 128, 128)
			else
				surface.SetDrawColor(50, 50, 50, 255)
				surface.DrawRect(0, 0, 128, 128)
				surface.SetDrawColor(mcol)
				surface.DrawRect(20, 20, 128 - 40, 128 - 40)
			end

			local votes = 0
			if GAMEMODE.MapVotesByMap[map] then
				votes = #GAMEMODE.MapVotesByMap[map]
			end

			local fg2 = draw.GetFontHeight("RobotoHUD-L10")
			if votes > 0 then
				draw.SimpleText(votes .. (votes > 1 && " votes" || " vote"), "RobotoHUD-L10", 128 + 20, 20 + fg + 20 + fg2, color_white, 0)
			end

			local i = 0
			for ply, map2 in pairs(GAMEMODE.MapVotes) do
				if IsValid(ply) && map2 == map then
					draw.SimpleText(ply:Nick(), "RobotoHUD-L10", w, i * fg2 - self.VotesScroll, gray, 2)
					i = i + 1
				end
			end

			if i * fg2 > 128 then
				self.VotesScroll = self.VotesScroll + FrameTime() * 14 * self.VotesScrollDir
				if self.VotesScroll > i * fg2 - 128 then
					self.VotesScrollDir = -1
				elseif self.VotesScroll < 0 then
					self.VotesScrollDir = 1
				end
			end
		end

		function but:DoClick()
			RunConsoleCommand("ph_votemap", map)
		end

		menu.MapVoteList:AddItem(but)
	end
end

function GM:OpenEndRoundMenu()
	if !IsValid(menu) then
		createEndRoundMenu()
	end

	menu:SetVisible(true)
end

function GM:CloseEndRoundMenu()
	if IsValid(menu) then
		menu:Close()
	end
end

function GM:ToggleEndRoundMenuVisibility()
	if IsValid(menu) && menu:IsVisible() then
		GAMEMODE:CloseEndRoundMenu()
	else
		GAMEMODE:OpenEndRoundMenu()
	end
end
