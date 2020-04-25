include("sv_awards.lua")

util.AddNetworkString("gamestate")
util.AddNetworkString("round_victor")
util.AddNetworkString("gamerules")

GM.GameState = GAMEMODE && GAMEMODE.GameState || ROUND_WAIT
GM.StateStart = GAMEMODE && GAMEMODE.StateStart || CurTime()
GM.Rounds = GAMEMODE && GAMEMODE.Rounds || 0

local function mapTimeLimitTimerResult()
	if GAMEMODE.Rounds < GAMEMODE.RoundLimit:GetInt() then -- Only change if we haven't already hit the round limit
		GAMEMODE.Rounds = GAMEMODE.RoundLimit:GetInt() - 1 -- Allows for 1 extra round before hitting the limit
	end
end

local function changeMapTimeLimitTimer(oldValueMinutes, newValueMinutes)
	local timerName = "ph_timer_map_time_limit"
	if newValueMinutes == -1 then -- Timer should be disabled
		timer.Remove(timerName)
	else
		local newValueSeconds = math.floor(newValueMinutes) * 60

		-- If a timer exists then take its elapsed time into account when calculating our new time limit.
		if timer.Exists(timerName) then
			local oldValueSeconds = math.floor(oldValueMinutes) * 60
			newValueSeconds = newValueSeconds - (oldValueSeconds - timer.TimeLeft(timerName))
		end

		-- Timers don't execute their callback if given a negative time.
		-- newValueSeconds will be negative if oldValueMinutes was greater than newValueMinutes.
		if newValueSeconds < 0 then
			mapTimeLimitTimerResult()
		else
			-- This will create or update the timer with the new value.
			timer.Create(timerName, newValueSeconds, 1, mapTimeLimitTimerResult)
		end
	end
end

cvars.AddChangeCallback("ph_map_time_limit", function(convar, oldValue, newValue)
	changeMapTimeLimitTimer(tonumber(oldValue), tonumber(newValue))
end)

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
	net.WriteUInt(self.GameState || ROUND_WAIT, 32)
	net.WriteDouble(self.StateStart || 0)
	net.Broadcast()
end

function GM:GetRoundSettings()
	self.RoundSettings = self.RoundSettings || {}
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
		if !ply:IsSpectator() then -- ignore spectators
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
		if !ply:IsSpectator() then -- ignore spectators
			ply:SetNWBool("RoundInGame", true)
			ply:KillSilent()
			ply:Spawn()

			local col = team.GetColor(ply:Team())
			ply:SetPlayerColor(Vector(col.r / 255, col.g / 255, col.b / 255))

			if ply:IsHunter() then
				ply:Freeze(true)
			end

			ply.PropDmgPenalty = 0
			ply.PropMovement = 0
			ply.HunterKills = 0
			ply.TauntAmount = 0
			ply.TauntsUsed = {}
			ply.TauntEnd = nil
			ply.AutoTauntDeadline = nil
		else
			ply:SetNWBool("RoundInGame", false)
		end
	end

	self:CleanupMap()
	self.Rounds = self.Rounds + 1

	if self.Rounds == self.RoundLimit:GetInt() then
		GlobalChatMsg(Color(255, 0, 0), "This is the LAST ROUND!")
	end

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

function GM:EndRound(winningTeam)
	if winningTeam == WIN_NONE then
		GlobalChatMsg("Tie everybody loses")
	else
		GlobalChatMsg(team.GetColor(winningTeam), team.GetName(winningTeam), " win")
	end

	self.LastRoundResult = winningTeam

	local awards = {}
	for awardKey, award in pairs(PlayerAwards) do -- PlayerAwards comes from sv_awards.lua
		local result = award.getWinner()

		-- nil values cannot exist in awards otherwise the net.WriteTable below will break
		if !result then
			continue
		elseif type(result) == "Player" then
			awards[awardKey] = {
				name = award.name,
				desc = award.desc,
				winnerName = result:Nick(),
				winnerTeam = result:Team()
			}
		else
			ErrorNoHalt("HUSKLESPH WARNING: EndRound Player Award gave non Player object: " .. type(result))
		end
	end

	net.Start("round_victor")
	net.WriteUInt(winningTeam, 8)
	net.WriteTable(awards)
	net.Broadcast()

	self.RoundSettings.NextRoundTime = 15
	self:NetworkGameSettings()
	self:SetGameState(ROUND_POST)
end

function GM:RoundsSetupPlayer(ply)
	-- start off not participating
	ply:SetNWBool("RoundInGame", false)

	-- send game state
	self:NetworkGameState(ply)
end

function GM:CheckForVictory()
	-- Check if time limit expired
	local settings = self:GetRoundSettings()
	local roundTime = settings.RoundTime || 5 * 60
	if self:GetStateRunningTime() > roundTime then
		self:EndRound(WIN_PROP)
		return
	end

	-- Check if there are still living players on either team
	local huntersAlive, propsAlive = false, false
	for _, ply in pairs(self:GetPlayingPlayers()) do
		if !ply:Alive() then continue end

		huntersAlive = huntersAlive || ply:IsHunter()
		propsAlive = propsAlive || ply:IsProp()
	end

	if !huntersAlive && !propsAlive then
		self:EndRound(WIN_NONE)
	elseif !huntersAlive then
		self:EndRound(WIN_PROP)
	elseif !propsAlive then
		self:EndRound(WIN_HUNTER)
	end
end

function GM:RoundsThink()
	if self:GetGameState() == ROUND_WAIT then
		local c = 0
		for k, ply in pairs(player.GetAll()) do
			if !ply:IsSpectator() then -- ignore spectators
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
			if ply:IsProp() && ply:Alive() then
				ply.PropMovement = (ply.PropMovement || 0) + ply:GetVelocity():Length()
			end
		end
	elseif self:GetGameState() == ROUND_POST then
		if self:GetStateRunningTime() > (self.RoundSettings.NextRoundTime || 30) then
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
	if !IsValid(ply) || ply:IsAdmin() || ply:IsSuperAdmin() || cvars.Bool("sv_cheats", 0) then
		GAMEMODE.RoundSettings = GAMEMODE.RoundSettings || {}
		GAMEMODE:EndRound(WIN_NONE)
	else
		ply:PrintMessage(HUD_PRINTCONSOLE, "You must be a GMod Admin or SuperAdmin on the server to use this command, or sv_cheats must be enabled.")
	end
end
concommand.Add("ph_endround", ForceEndRound)
