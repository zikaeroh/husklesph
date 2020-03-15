local PlayerMeta = FindMetaTable("Player")

GM.GameState = GAMEMODE and GAMEMODE.GameState or 0
GM.StateStart = GAMEMODE and GAMEMODE.StateStart or CurTime()

function GM:GetGameState()
	return self.GameState
end

function GM:GetStateStart()
	return self.StateStart
end

function GM:GetStateRunningTime()
	return CurTime() - self.StateStart
end

net.Receive("gamestate", function (len)
	GAMEMODE.GameState = net.ReadUInt(32)
	GAMEMODE.StateStart = net.ReadDouble()

	if GAMEMODE.GameState == 1 then
		GAMEMODE.UpgradesNotif = {}
		GAMEMODE.KillFeed = {}
	end

	if GAMEMODE.GameState != 2 then
		GAMEMODE:CloseEndRoundMenu()
	end
end)

net.Receive("round_victor", function (len)
	local tab = {}
	tab.reason = net.ReadUInt(8)
	if tab.reason == 2 || tab.reason == 3 then
		tab.winningTeam = net.ReadUInt(16)
	end
	
	tab.playerAwards = {}
	while net.ReadUInt(8) != 0 do
		local k = net.ReadString()
		local v = net.ReadEntity()
		local col = net.ReadVector()
		local name = net.ReadString()
		tab.playerAwards[k] = {
			player = v,
			name = name,
			color = team.GetColor(v:Team())
		}
	end

	// open the results panel
	timer.Simple(2, function ()
		GAMEMODE:EndRoundMenuResults(tab)
	end)
end)

net.Receive("gamerules", function ()

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
	self.RoundSettings = self.RoundSettings or {}
	return self.RoundSettings 
end