local PlayerMeta = FindMetaTable("Player")

util.AddNetworkString("gamestate")
util.AddNetworkString("round_victor")
util.AddNetworkString("gamerules")

GM.GameState = GAMEMODE and GAMEMODE.GameState or ROUND_WAIT
GM.StateStart = GAMEMODE and GAMEMODE.StateStart or CurTime()
GM.Rounds = GAMEMODE and GAMEMODE.Rounds or 0


function GM:GetGameState()
	return self.GameState
end

function GM:GetStateStart()
	return self.StateStart
end

function GM:GetStateRunningTime()
	return CurTime() - self.StateStart
end

function GM:GetPlayingPlayers()
	local players = {}
	for k, ply in pairs(player.GetAll()) do
		if !ply:IsSpectator() && ply:GetNWBool("RoundInGame") then
			table.insert(players, ply)
		end
	end
	return players
end

function GM:SetGameState(state)
	self.GameState = state
	self.StateStart = CurTime()
	self:NetworkGameState()
end

function GM:NetworkGameState(ply)
	net.Start("gamestate")
	net.WriteUInt(self.GameState or ROUND_WAIT, 32)
	net.WriteDouble(self.StateStart or 0)
	net.Broadcast()
end

function GM:GetRoundSettings()
	self.RoundSettings = self.RoundSettings or {}
	return self.RoundSettings 
end

function GM:NetworkGameSettings(ply)
	net.Start("gamerules")

	if self.RoundSettings then
		for k, v in pairs(self.RoundSettings) do
			net.WriteUInt(1, 8)
			net.WriteString(k)
			net.WriteType(v)
		end
	end
	net.WriteUInt(0, 8)

	if ply == nil then
		net.Broadcast()
	else
		net.Send(ply)
	end
end

function GM:SetupRound()
	local c = 0
	for k, ply in pairs(player.GetAll()) do
		if !ply:IsSpectator() then // ignore spectators
			c = c + 1
		end
	end
	if c < 2 then
		GlobalChatMsg("Not enough players to start round")
		self:SetGameState(ROUND_WAIT)
		return
	end

	self:BalanceTeams()

	for k, ply in pairs(player.GetAll()) do
		if !ply:IsSpectator() then // ignore spectators
			ply:SetNWBool("RoundInGame", true)
			ply:KillSilent()
			ply:Spawn()

			local col = team.GetColor(ply:Team())
			ply:SetPlayerColor(Vector(col.r / 255, col.g / 255, col.b / 255))

			if ply:IsHunter() then
				ply:Freeze(true)
			end

			ply.TauntsUsed = {}
			ply.TauntEnd = nil
			ply.AutoTauntDeadline = nil
		else
			ply:SetNWBool("RoundInGame", false)
		end
	end
	self:CleanupMap()
	
	self.Rounds = self.Rounds + 1
	hook.Run("OnSetupRound")
	self:SetGameState(ROUND_HIDE)
end

function GM:StartRound()

	self.LastPropDeath = nil
	self.FirstHunterKill = nil

	local hunters, props = 0, 0
	for k, ply in pairs(self:GetPlayingPlayers()) do
		ply:Freeze(false)
		ply.PropDmgPenalty = 0
		ply.PropMovement = 0
		ply.HunterKills = 0
		ply.TauntAmount = 0
		if ply:IsHunter() then
			hunters = hunters + 1
		elseif ply:IsProp() then
			props = props + 1
		end
	end

	local c = 0
	for k, ent in pairs(ents.GetAll()) do
		if ent.IsDisguisableAs && ent:IsDisguisableAs() then
			c = c + 1
		end
	end

	self.RoundSettings = {}
	self.RoundSettings.RoundTime = math.Round((c * 0.5 / hunters + 60 * 4)  * math.sqrt(props / hunters))
	self.RoundSettings.PropsCamDistance = self.PropsCamDistance:GetFloat()
	print("Round time is " .. (self.RoundSettings.RoundTime / 60) .. " (" .. c .. " props)")

	self:NetworkGameSettings()
	self:SetGameState(ROUND_SEEK)

	GlobalChatMsg("Round has started")

end

function GM:EndRound(reason)
	local winningTeam
	if reason == WIN_NONE then
		GlobalChatMsg("Tie everybody loses")
	elseif reason == WIN_HUNTER then
		GlobalChatMsg(team.GetColor(TEAM_HUNTER), team.GetName(TEAM_HUNTER), " win")
		winningTeam = TEAM_HUNTER
	elseif reason == WIN_PROP then
		GlobalChatMsg(team.GetColor(TEAM_PROP), team.GetName(TEAM_PROP), " win")
		winningTeam = TEAM_PROP
	end
	self.LastRoundResult = reason

	self.PlayerAwards = {}

	local propPly, propDmg = nil, 0
	local killsPly, killsAmo = nil, 0
	local leastMovePly, leastMoveAmo
	local mostMovePly, mostMoveAmo
	local tauntsPly, tauntsAmo = nil, 0
	for k, ply in pairs(self:GetPlayingPlayers()) do

		// TODO replace with better statistic tracker
		ply.HunterKills = ply.HunterKills or 0
		ply.PropDmgPenalty = ply.PropDmgPenalty or 0
		ply.TauntAmount = ply.TauntAmount or 0
		ply.PropMovement = ply.PropMovement or 0

		if ply:IsHunter() then // hunters

			// get hunter with most prop damage
			if ply.PropDmgPenalty > propDmg then
				propDmg = ply.PropDmgPenalty
				propPly = ply
			end

			// get hunter with most kills
			if ply.HunterKills > killsAmo then
				killsAmo = ply.PropDmgPenalty
				killsPly = ply
			end
		else

			// get prop with least movement
			if leastMoveAmo == nil || ply.PropMovement < leastMoveAmo then
				leastMoveAmo = ply.PropMovement
				leastMovePly = ply
			end
			
			// get prop with most movement
			if mostMoveAmo == nil || ply.PropMovement > mostMoveAmo then
				mostMoveAmo = ply.PropMovement
				mostMovePly = ply
			end

			// get prop with most taunts
			if ply.TauntAmount > tauntsAmo then
				tauntsAmo = ply.TauntAmount
				tauntsPly = ply
			end
		end
	end

	if propPly then
		self.PlayerAwards["PropDamage"] = propPly
	end

	if leastMovePly then
		self.PlayerAwards["LeastMovement"] = leastMovePly
	end
	
	if mostMovePly then
		self.PlayerAwards["MostMovement"] = mostMovePly
	end
	
	if killsPly then
		self.PlayerAwards["MostKills"] = killsPly
	end

	if tauntsPly then
		self.PlayerAwards["MostTaunts"] = tauntsPly
	end

	// last prop death award
	if IsValid(self.LastPropDeath) && reason == WIN_HUNTER then
		self.PlayerAwards["LastPropStanding"] = self.LastPropDeath
	end

	// first hunter kill award
	if IsValid(self.FirstHunterKill) then
		self.PlayerAwards["FirstHunterKill"] = self.FirstHunterKill
	end

	net.Start("round_victor")
	net.WriteUInt(reason, 8)
	if winningTeam then
		net.WriteUInt(winningTeam, 16)
	end
	for k, v in pairs(self.PlayerAwards) do
		net.WriteUInt(1, 8)
		net.WriteString(tostring(k))
		net.WriteEntity(v)
		net.WriteVector(v:GetPlayerColor())
		net.WriteString(v:Nick())
	end
	net.WriteUInt(0, 8)
	net.Broadcast()

	self.RoundSettings.NextRoundTime = 15
	self:NetworkGameSettings()

	for k, ply in pairs(self:GetPlayingPlayers()) do
		if ply:Team() == winningTeam then
		else
		end
	end
	self:SetGameState(ROUND_POST)
end

function GM:RoundsSetupPlayer(ply)
	// start off not participating
	ply:SetNWBool("RoundInGame", false)

	// send game state
	self:NetworkGameState(ply)
end

function GM:CheckForVictory()
	local settings = self:GetRoundSettings()
	local roundTime = settings.RoundTime or 5 * 60
	if self:GetStateRunningTime() > roundTime then
		self:EndRound(WIN_PROP)
		return
	end

	local red, blue = 0, 0
	for k, ply in pairs(self:GetPlayingPlayers()) do
		if ply:Alive() then
			if ply:IsHunter() then
				red = red + 1
			elseif ply:IsProp() then
				blue = blue + 1
			end
		end
	end
	if red == 0 && blue == 0 then
		self:EndRound(WIN_NONE)
		return
	end

	if red == 0 then
		self:EndRound(WIN_PROP)
		return
	end
	if blue == 0 then
		self:EndRound(WIN_HUNTER)
		return
	end
end

function GM:RoundsThink()
	if self:GetGameState() == ROUND_WAIT then
		local c = 0
		for k, ply in pairs(player.GetAll()) do
			if !ply:IsSpectator() then // ignore spectators
				c = c + 1
			end
		end
		if c >= 2 && self.RoundWaitForPlayers + self.StartWaitTime:GetFloat() < CurTime() then
			self:SetupRound()
		end
	elseif self:GetGameState() == ROUND_HIDE then
		if self:GetStateRunningTime() > 30 then
			self:StartRound()
		end
	elseif self:GetGameState() == ROUND_SEEK then
		self:CheckForVictory()

		for k, ply in pairs(self:GetPlayingPlayers()) do
			if ply:IsProp() then
				ply.PropMovement = (ply.PropMovement or 0) + ply:GetVelocity():Length()
			end
		end
	elseif self:GetGameState() == ROUND_POST then
		if self:GetStateRunningTime() > (self.RoundSettings.NextRoundTime or 30) then
			if self.RoundLimit:GetInt() > 0 && self.Rounds >= self.RoundLimit:GetInt() then
				self:StartMapVote()
			else
				if self.LastRoundResult != WIN_PROP || !self.PropsWinStayProps:GetBool() then
					self:SwapTeams()
				end
				self:SetupRound()
			end
		end
	elseif self:GetGameState() == ROUND_MAPVOTE then
		self:MapVoteThink()
	end
end

local function ForceEndRound(ply, command, args)
   -- ply is nil on dedicated server console
    if (not IsValid(ply)) or ply:IsAdmin() or ply:IsSuperAdmin() or cvars.Bool("sv_cheats", 0) then
		GAMEMODE.RoundSettings = GAMEMODE.RoundSettings or {}
        GAMEMODE:EndRound(WIN_NONE)
    else
        ply:PrintMessage(HUD_PRINTCONSOLE, "You must be a GMod Admin or SuperAdmin on the server to use this command, or sv_cheats must be enabled.")
    end
end
concommand.Add("ph_endround", ForceEndRound)
