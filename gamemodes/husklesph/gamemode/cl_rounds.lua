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
		GAMEMODE.KillFeed = {}
	end

	if GAMEMODE.GameState != ROUND_SEEK then
		GAMEMODE:CloseEndRoundMenu()
	end
end)

net.Receive("round_victor", function(len)
	local tab = {}
	tab.reason = net.ReadUInt(8)
	if tab.reason == WIN_HUNTER || tab.reason == WIN_PROP then
		tab.winningTeam = net.ReadUInt(16)
	end

	tab.playerAwards = net.ReadTable()

	-- open the results panel
	timer.Simple(2, function()
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
