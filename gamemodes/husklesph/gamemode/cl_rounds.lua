GM.GameState = GAMEMODE && GAMEMODE.GameState || ROUND_WAIT
GM.StateStart = GAMEMODE && GAMEMODE.StateStart || CurTime()

function GM:GetGameState()
	return self.GameState
end

function GM:GetStateStart()
	return self.StateStart
end

function GM:GetStateRunningTime()
	return CurTime() - self.StateStart
end

net.Receive("gamestate", function(len)
	GAMEMODE.GameState = net.ReadUInt(32)
	GAMEMODE.StateStart = net.ReadDouble()

	if GAMEMODE.GameState == ROUND_HIDE then
		GAMEMODE.UpgradesNotif = {}
		GAMEMODE.ClearKillFeed()
	end

	if GAMEMODE.GameState != ROUND_SEEK then
		GAMEMODE:CloseEndRoundMenu()
	end
end)

net.Receive("round_victor", function(len)
	local tab = {}
	tab.winningTeam = net.ReadUInt(8)
	tab.playerAwards = net.ReadTable()

	-- open the results panel
	timer.Create("ph_timer_show_results_delay", 2, 1, function()
		GAMEMODE:EndRoundMenuResults(tab)
	end)
end)

net.Receive("gamerules", function()
	local settings = {}
	while net.ReadUInt(8) != 0 do
		local k = net.ReadString()
		local t = net.ReadUInt(8)
		local v = net.ReadType(t)
		settings[k] = v
	end

	GAMEMODE.RoundSettings = settings
end)

function GM:GetRoundSettings()
	self.RoundSettings = self.RoundSettings || {}
	return self.RoundSettings
end
