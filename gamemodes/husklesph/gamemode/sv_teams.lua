concommand.Add("ph_jointeam", function(ply, com, args)
	local newTeam = tonumber(args[1]) || TEAM_SPEC -- Default to spectators if there's a problem
	if ply:Team() == newTeam then return end

	-- Always able to join spectator team
	-- Can join team hunter or team prop if team sizes are equal
	-- Otherwise, can only join the smaller team
	if newTeam == TEAM_SPEC || team.NumPlayers(TEAM_HUNTER) - team.NumPlayers(TEAM_PROP) == 0 || newTeam == team.BestAutoJoinTeam() then
		if ply:Alive() then ply:Kill() end
		ply:SetTeam(newTeam)
		GlobalChatMsg(ply:Nick(), " changed team to ", team.GetColor(newTeam), team.GetName(newTeam))
	else
		ply:PlayerChatMsg("Team full, you cannot join")
	end
end)

function GM:BalanceTeams()
	local teamDiff = team.NumPlayers(TEAM_HUNTER) - team.NumPlayers(TEAM_PROP)
	if math.abs(teamDiff) <= 1 then return end -- Only balance if teams are off by 2 or more players

	local biggerTeam, smallerTeam = TEAM_PROP, TEAM_HUNTER -- Assume props had more players
	if teamDiff > 1 then -- teamDiff > 1 means hunters had more players
		biggerTeam = TEAM_HUNTER
		smallerTeam = TEAM_PROP
	end

	-- Continuously swap random players from biggerTeam to smallerTeam until sizes are balanced
	teamDiff = math.abs(teamDiff)
	while teamDiff > 1 do
		local players = team.GetPlayers(biggerTeam)
		local ply = players[math.random(#players)]
		ply:SetTeam(smallerTeam)
		GlobalChatMsg(ply:Nick(), " team balanced to ", team.GetColor(smallerTeam), team.GetName(smallerTeam))
		teamDiff = teamDiff - 2
	end
end

function GM:SwapTeams()
	for _, ply in pairs(player.GetAll()) do
		if ply:IsHunter() then
			ply:SetTeam(TEAM_PROP)
		elseif ply:IsProp() then
			ply:SetTeam(TEAM_HUNTER)
		end
	end

	GlobalChatMsg(Color(50, 220, 150), "Teams have been swapped")
end
