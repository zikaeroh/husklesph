function GM:TeamsSetupPlayer(ply)
	local hunters = team.NumPlayers(TEAM_HUNTER)
	local props = team.NumPlayers(TEAM_PROP)
	if props <= hunters then
		ply:SetTeam(TEAM_PROP)
	else
		ply:SetTeam(TEAM_HUNTER)
	end
end

concommand.Add("ph_jointeam", function(ply, com, args)
	local curteam = ply:Team()
	local newteam = tonumber(args[1]) || TEAM_SPEC -- Default to spectators if there's a problem
	if curteam == newteam then return end

	if newteam == TEAM_SPEC then
		ply:SetTeam(newteam)
		if ply:Alive() then
			ply:Kill()
		end

		GlobalChatMsg(ply:Nick(), " changed team to ", team.GetColor(newteam), team.GetName(newteam))
	elseif newteam == TEAM_HUNTER || newteam == TEAM_PROP then
		-- make sure we can't join the bigger team
		local otherteam = newteam == TEAM_HUNTER && TEAM_PROP || TEAM_HUNTER
		if team.NumPlayers(newteam) <= team.NumPlayers(otherteam) then
			ply:SetTeam(newteam)
			if ply:Alive() then
				ply:Kill()
			end

			GlobalChatMsg(ply:Nick(), " changed team to ", team.GetColor(newteam), team.GetName(newteam))
		else
			ply:PlayerChatMsg("Team full, you cannot join")
		end
	end
end)

function GM:CheckTeamBalance()
	if !self.TeamBalanceCheck || self.TeamBalanceCheck < CurTime() then
		self.TeamBalanceCheck = CurTime() + 3 * 60 -- check every 3 minutes
		local diff = team.NumPlayers(TEAM_HUNTER) - team.NumPlayers(TEAM_PROP)
		if diff < -1 || diff > 1 then -- teams must be off by more than 2 for team balance
			self.TeamBalanceTimer = CurTime() + 30 -- balance in 30 seconds
			for k, ply in pairs(player.GetAll()) do
				ply:ChatPrint("Auto team balance in 30 seconds")
			end
		end
	end

	if self.TeamBalanceTimer && self.TeamBalanceTimer < CurTime() then
		self.TeamBalanceTimer = nil
		self:BalanceTeams()
	end
end

function GM:BalanceTeams(nokill)
	local diff = team.NumPlayers(TEAM_HUNTER) - team.NumPlayers(TEAM_PROP)
	if diff < -1 || diff > 1 then -- teams must be off by more than 2 for team balance
		local biggerTeam, smallerTeam = TEAM_PROP, TEAM_HUNTER
		if diff > 0 then
			biggerTeam = TEAM_HUNTER
			smallerTeam = TEAM_PROP
		end

		diff = team.NumPlayers(biggerTeam) - team.NumPlayers(smallerTeam)
		while diff > 1 do
			local players = team.GetPlayers(biggerTeam)
			local ply = players[math.random(#players)]
			ply:SetTeam(smallerTeam)
			if !nokill && ply:Alive() then
				ply:Kill()
			end

			GlobalChatMsg(ply:Nick(), " team balanced to ", team.GetColor(smallerTeam), team.GetName(smallerTeam))
			diff = diff - 2
		end
	end
end

function GM:SwapTeams()
	for k, ply in pairs(player.GetAll()) do
		if ply:IsHunter() then
			ply:SetTeam(TEAM_PROP)
		elseif ply:IsProp() then
			ply:SetTeam(TEAM_HUNTER)
		end
	end

	GlobalChatMsg(Color(50, 220, 150), "Teams have been swapped")
end
