local PlayerMeta = FindMetaTable("Player")

function GM:PlayerInitialSpawn(ply)
	self:RoundsSetupPlayer(ply)
	self:TeamsSetupPlayer(ply)

	if self:GetGameState() != ROUND_WAIT then
		timer.Simple(0, function()
			if IsValid(ply) then
				ply:KillSilent()
			end
		end)
	end

	self.LastPlayerSpawn = CurTime()

	if self:IsMapVoting() then
		self:NetworkMapVoteStart(ply)
	end
end

function GM:PlayerLoadedLocalPlayer(ply)
	self:SetTauntMenuPhrase(self.TauntMenuPhrase:GetString(), ply)
end

net.Receive("clientIPE", function(len, ply)
	if !ply.ClientIPE then
		ply.ClientIPE = true
		hook.Call("PlayerLoadedLocalPlayer", GAMEMODE, ply)
	end
end)

function GM:PlayerDisconnected(ply)
	ply:SetTeam(TEAM_HUNTER)
end

util.AddNetworkString("hull_set")

function GM:PlayerSpawn(ply)
	ply:UnCSpectate()

	player_manager.OnPlayerSpawn(ply)
	player_manager.RunClass(ply, "Spawn")

	hook.Call("PlayerLoadout", GAMEMODE, ply)
	hook.Call("PlayerSetModel", GAMEMODE, ply)

	ply:UnDisguise()
	ply:CalculateSpeed()

	ply:SetHMaxHealth(100)
	ply:SetHealth(ply:GetHMaxHealth())

	GAMEMODE:PlayerSetNewHull(ply)
	self:PlayerSetupHands(ply)

	local col = team.GetColor(ply:Team())
	local vec = Vector(col.r / 255,col.g / 255,col.b / 255)
	ply:SetPlayerColor(vec)

	ply.LastSpawnTime = CurTime()
end

function GM:PlayerSetupHands(ply)
	local oldhands = ply:GetHands()
	if (IsValid(oldhands)) then oldhands:Remove() end

	local hands = ents.Create("gmod_hands")
	if (IsValid(hands)) then
		ply:SetHands(hands)
		hands:SetOwner(ply)

		-- Which hands should we use?
		local cl_playermodel = ply:GetInfo("cl_playermodel")
		local info = player_manager.TranslatePlayerHands(cl_playermodel)
		if (info) then
			hands:SetModel(info.model)
			hands:SetSkin(info.skin)
			hands:SetBodyGroups(info.body)
		end

		-- Attach them to the viewmodel
		local vm = ply:GetViewModel(0)
		hands:AttachToViewmodel(vm)

		vm:DeleteOnRemove(hands)
		ply:DeleteOnRemove(hands)

		hands:Spawn()
	end
end

function PlayerMeta:CalculateSpeed()
	-- set the defaults
	local settings = {
		walkSpeed = 250,
		runSpeed = 50,
		jumpPower = 200,
		canRun = true,
		canMove = true,
		canJump = true
	}

	-- speed penalty for small objects (popcan, small bottles, mouse, etc)
	if self:IsDisguised() then
		if GAMEMODE.PropsSmallSize:GetFloat() > 0 then
			local mul = math.Clamp(self:GetNWFloat("disguiseVolume", 1) / GAMEMODE.PropsSmallSize:GetFloat(), 0.5, 1)
			settings.walkSpeed = settings.walkSpeed * mul
		end

		if settings.runSpeed > settings.walkSpeed then
			settings.runSpeed = settings.walkSpeed
		end

		settings.jumpPower = settings.jumpPower * GAMEMODE.PropsJumpPower:GetFloat()
	end

	hook.Call("PlayerCalculateSpeed", ply, settings)

	-- set out new speeds
	if settings.canRun then
		self:SetRunSpeed(settings.runSpeed || 1)
	else
		self:SetRunSpeed(settings.walkSpeed || 1)
	end

	if self:GetMoveType() != MOVETYPE_NOCLIP then
		if settings.canMove then
			self:SetMoveType(MOVETYPE_WALK)
		else
			self:SetMoveType(MOVETYPE_NONE)
		end
	end

	self.CanRun = settings.canRun
	self:SetWalkSpeed(settings.walkSpeed || 1)
	self:SetJumpPower(settings.jumpPower || 1)
end

function GM:PlayerLoadout(ply)
	if ply:IsHunter() then
		ply:Give("weapon_crowbar")
		ply:Give("weapon_smg1")
		ply:Give("weapon_shotgun")

		ply:GiveAmmo(45 * 10, "SMG1")
		ply:GiveAmmo(6 * 10, "buckshot")
		local amo = self.HunterGrenadeAmount:GetInt()
		if amo > 0 then
			ply:GiveAmmo(amo, "SMG1_Grenade")
		end
	end
end

local playerModels = {}
local function addModel(model, sex)
	local t = {}
	t.model = model
	t.sex = sex
	table.insert(playerModels, t)
end

addModel("male03", "male")
addModel("male04", "male")
addModel("male05", "male")
addModel("male07", "male")
addModel("male06", "male")
addModel("male09", "male")
addModel("male01", "male")
addModel("male02", "male")
addModel("male08", "male")
addModel("female06", "female")
addModel("female01", "female")
addModel("female03", "female")
addModel("female05", "female")
addModel("female02", "female")
addModel("female04", "female")
addModel("refugee01", "male")
addModel("refugee02", "male")
addModel("refugee03", "male")
addModel("refugee04", "male")

function GM:PlayerSetModel(ply)
	local cl_playermodel = ply:GetInfo("cl_playermodel")
	local playerModel = table.Random(playerModels)
	cl_playermodel = playerModel.model

	local modelname = player_manager.TranslatePlayerModel(cl_playermodel)
	util.PrecacheModel(modelname)
	ply:SetModel(modelname)
	ply.ModelSex = playerModel.sex

	net.Start("player_model_sex")
	net.WriteString(playerModel.sex)
	net.Send(ply)
end

function GM:PlayerDeathSound()
	return true
end

-- This is only a shallow copy.
local function mergeTables(...)
	local args = {...}
	local newTable = {}
	for _, tbl in ipairs(args) do
		for _, value in ipairs(tbl) do
			table.insert(newTable, value)
		end
	end

	return newTable
end

-------------------------------
-------------------------------
-------------------------------

-- Most of the following code from this comment block down to the next is from TTT.
-- The code provides the functionality for automatically generating spawnpoints if
-- necessary. Prophunters sort-of-not-really had a system for doing this but it
-- basically just killed players every time or got them stuck in each other so it
-- was not very useful. The TTT code has been tweaked to work better with Prophunters.

-- Nice Fisher-Yates implementation, from Wikipedia
local rand = math.random
local function shuffleTable(t)
	local n = #t
	while n > 2 do
		-- n is now the last pertinent index
		local k = rand(n) -- 1 <= k <= n
		-- Quick swap
		t[n], t[k] = t[k], t[n]
		n = n - 1
	end

	return t
end

function GM:IsSpawnpointSuitable(ply, spwn, force, rigged)
	if !IsValid(ply) || ply:IsSpectator() then return true end
	if !rigged && (!IsValid(spwn) || !spwn:IsInWorld()) then return false end

	-- spwn is normally an ent, but we sometimes use a vector for jury rigged
	-- positions
	local pos = rigged && spwn || spwn:GetPos()
	if !util.IsInWorld(pos) then return false end

	local blocking = ents.FindInBox(pos + Vector(-32, -32, 0), pos + Vector(32, 32, 64)) -- Changed from (-16, -16, 0) (16, 16, 64)
	for _, blockingEnt in ipairs(blocking) do
		if IsValid(blockingEnt) && blockingEnt:IsPlayer() && !blockingEnt:IsSpectator() && blockingEnt:Alive() then
			if force then
				blockingEnt:Kill()
				blockingEnt:PlayerChatMsg(Color(200, 20, 20), "You were killed because there are not enough spawnpoints.")
				for _, value in ipairs(player.GetAll()) do
					if value:IsAdmin() || value:IsSuperAdmin() then
						value:PlayerChatMsg(Color(200, 20, 20), "Not enough spawnpoints; " .. blockingEnt:Nick() .. " has been killed to spawn " .. ply:Nick() .. ".")
					end
				end
			else
				return false
			end
		end
	end

	return true
end

-- TTT only had a single table for spawnpoints but we're going to use three different ones
-- so that we can try to group teams together.
local propSpawnTypes = {"info_player_terrorist", "info_player_axis",
"info_player_combine", "info_player_pirate", "info_player_viking",
"diprip_start_team_blue", "info_player_blue", "info_player_human"}

local hunterSpawnTypes = {"info_player_counterterrorist",
"info_player_allies", "info_player_rebel", "info_player_knight",
"diprip_start_team_red", "info_player_red", "info_player_zombie"}

-- These spawn types should ideally only be used for spectators. Hunters/props spawning here
-- will probably fall out of the world.
local spectatorSpawnTypes = {"info_player_start", "gmod_player_start",
"info_player_teamspawn", "ins_spawnpoint", "aoc_spawnpoint",
"dys_spawn_point", "info_player_coop", "info_player_deathmatch"}

local function getSpawnEnts(plyTeam, force_all)
	local tblToUse
	if plyTeam == TEAM_PROP then
		tblToUse = propSpawnTypes
	elseif plyTeam == TEAM_HUNTER then
		tblToUse = hunterSpawnTypes
	else
		tblToUse = spectatorSpawnTypes
	end

	local tbl = {}
	for _, classname in ipairs(tblToUse) do
		for _, e in ipairs(ents.FindByClass(classname)) do
			if IsValid(e) && (!e.BeingRemoved) then
				table.insert(tbl, e)
			end
		end
	end

	-- If necessary, ignore the plyTeam restriction and use ALL spawnpoints.
	if force_all || #tbl == 0 then
		local allSpawnTypes = mergeTables(propSpawnTypes, hunterSpawnTypes, spectatorSpawnTypes)
		for _, classname in ipairs(allSpawnTypes) do
			for _, e in ipairs(ents.FindByClass(classname)) do
				if IsValid(e) && (!e.BeingRemoved) then
					table.insert(tbl, e)
				end
			end
		end
	end

	shuffleTable(tbl)
	return tbl
end

-- Generate points next to and above the spawn that we can test for suitability (a "3x3 grid")
local function pointsAroundSpawn(spwn)
	if !IsValid(spwn) then return {} end

	local pos = spwn:GetPos()
	local w, _ = 50, 72 -- Increased from the default 36, 72 as it seems to work better with Prophunters.

	-- all rigged positions
	-- could be done without typing them out, but would take about as much time
	return {
		pos + Vector(w,  0,  0),
		pos + Vector(0,  w,  0),
		pos + Vector(w,  w,  0),
		pos + Vector(-w,  0,  0),
		pos + Vector(0, -w,  0),
		pos + Vector(-w, -w,  0),
		pos + Vector(-w,  w,  0),
		pos + Vector(w, -w,  0)
	};
end

function GM:PlayerSelectSpawn(ply)
	local plyTeam = ply:Team()

	-- Should be true when the first player joins the game
	if !self.SpawnPoints then
		self.SpawnPoints = {}
	end

	-- Should be true for each first player on a team
	if !self.SpawnPoints[plyTeam] || (table.IsEmpty(self.SpawnPoints[plyTeam])) || (!IsTableOfEntitiesValid(self.SpawnPoints[plyTeam])) then
		self.SpawnPoints[plyTeam] = getSpawnEnts(plyTeam, false)
		-- One might think that we have to regenerate our spawnpoint
		-- cache. Otherwise, any rigged spawn entities would not get reused, and
		-- MORE new entities would be made instead. In reality, the map cleanup at
		-- round start will remove our rigged spawns, and we'll have to create new
		-- ones anyway.
	end

	if table.IsEmpty(self.SpawnPoints[plyTeam]) then
		Error("No spawn entity found!\n")
		return
	end

	-- Just always shuffle, it's not that costly and should help spawn
	-- randomness.
	shuffleTable(self.SpawnPoints[plyTeam])

	-- Optimistic attempt: assume there are sufficient spawns for all and one is
	-- free
	for _, spwn in pairs(self.SpawnPoints[plyTeam]) do
		if self:IsSpawnpointSuitable(ply, spwn, false) then
			return spwn
		end
	end

	-- That did not work, so now look around spawns
	local picked = nil
	for _, spwn in pairs(self.SpawnPoints[plyTeam]) do
		picked = spwn -- just to have something if all else fails

		-- See if we can jury rig a spawn near this one
		local rigged = pointsAroundSpawn(spwn)
		for _, rig in pairs(rigged) do
			if self:IsSpawnpointSuitable(ply, rig, false, true) then
				local spawnType
				if ply:IsProp() then
					spawnType = "info_player_terrorist"
				elseif ply:IsHunter() then
					spawnType = "info_player_counterterrorist"
				else
					spawnType = "info_player_start"
				end

				local rigSpwn = ents.Create(spawnType)
				if IsValid(rigSpwn) then
					rigSpwn:SetPos(rig)
					rigSpwn:Spawn()

					ErrorNoHalt("PROPHUNTERS WARNING: Map has too few spawn points, using a rigged spawn for " .. tostring(ply:Nick()) .. "\n")

					self.HaveRiggedSpawn = true
					return rigSpwn
				end
			end
		end
	end

	-- Last attempt, force one (this could kill other players)
	for _, spwn in pairs(self.SpawnPoints[plyTeam]) do
		if self:IsSpawnpointSuitable(ply, spwn, true) then
			return spwn
		end
	end

	return picked
end

-- TTT code ends here.

-----------------------------------
-----------------------------------
-----------------------------------

function GM:PlayerDeathThink(ply)
	if self:CanRespawn(ply) then
		ply:Spawn()
	else
		self:ChooseSpectatee(ply)
	end
end

local defaultDeathsound = Sound("ambient/voices/f_scream1.wav")
local deathsoundsFile = file.Read(GM.Folder .. "/ph_deathsounds.txt", "GAME") || ""
local deathsounds = util.KeyValuesToTable(deathsoundsFile, true, true)

for _, v in pairs(deathsounds) do
	if type(v) == "string" then
		resource.AddFile(Sound(v))
		continue
	end

	for _, s in ipairs(v) do
		resource.AddFile(Sound(s))
	end
end

local function chooseDeathsound(key)
	local ds = deathsounds[key]
	if !ds then return nil end
	if type(ds) == "string" then return ds end
	if #ds == 0 then return nil end
	return table.Random(ds)
end

local function randomDeathsound(ply)
	return chooseDeathsound(ply:SteamID()) || chooseDeathsound("default") || defaultDeathsound
end

function GM:DoPlayerDeath(ply, attacker, dmginfo)
	if ply:IsDisguised() && ply:IsProp() then
		ply:EmitSound(randomDeathsound(ply))
	end

	if ply.TauntsUsed then
		for k, v in pairs(ply.TauntsUsed) do
			ply:StopSound(k)
		end
	end

	ply.TauntsUsed = {}
	ply.TauntEnd = nil
	ply.AutoTauntDeadline = nil

	-- are they a prop
	if ply:IsProp() then
		-- set the last death award
		self.LastPropDeath = ply
	end

	ply:UnDisguise()
	ply:Freeze(false) -- why?, *sigh*
	ply:CreateRagdoll()

	local ent = ply:GetNWEntity("DeathRagdoll")
	if IsValid(ent) then
		ply:CSpectate(OBS_MODE_CHASE, ent)
	end

	ply:AddDeaths(1)

	if IsValid(attacker) && attacker:IsPlayer() then
		if attacker == ply then
			attacker:AddFrags(-1)
		else
			attacker:AddFrags(1)

			-- did a hunter kill a prop
			if attacker:IsHunter() && ply:IsProp() then
				-- increase their round kills
				attacker.HunterKills = (attacker.HunterKills || 0) + 1

				-- set the first hunter kill award
				if self.FirstHunterKill == nil then
					self.FirstHunterKill = attacker
				end
			end
		end
	end

	self:AddKillFeed(ply, attacker, dmginfo)
end

function GM:PlayerDeath(ply, inflictor, attacker)
	ply.NextSpawnTime = CurTime() + 1
	ply.DeathTime = CurTime()

	-- time until player can spectate another player
	ply.SpectateTime = CurTime() + 2
end

function GM:KeyPress(ply, key)
	if ply:Alive() then
		if key == IN_ATTACK then
			self:PlayerDisguise(ply)
		end
	end
end

function GM:PlayerSwitchFlashlight(ply)
	if ply:IsDisguised() then
		return false
	end

	return true
end

function GM:PlayerShouldTaunt(ply, actid)
	return false
end

function GM:PlayerCanSeePlayersChat(text, teamOnly, listener, speaker)
	if !IsValid(speaker) then return false end
	local canhear = self:PlayerCanHearChatVoice(listener, speaker, "chat", teamOnly)
	return canhear
end

function GM:StartCommand(ply, cmd)
	if ply:IsBot() then
		cmd:SetForwardMove(0)
		cmd:SetSideMove(0)
		cmd:SetViewAngles(Angle(0, 0, 0))
		self:BotMove(ply, cmd)
	end
end

local sv_alltalk = GetConVar("sv_alltalk")
function GM:PlayerCanHearPlayersVoice(listener, talker)
	if !IsValid(talker) then return false end
	return self:PlayerCanHearChatVoice(listener, talker, "voice")
end

function GM:PlayerCanHearChatVoice(listener, talker, typ, teamOnly)
	if typ == "chat" && teamOnly then
		if listener:Team() != talker:Team() then
			return false
		end
	end

	if sv_alltalk:GetBool() then
		return true
	end

	if self:GetGameState() == ROUND_POST || self:GetGameState() == ROUND_WAIT then
		return true
	end

	-- spectators and dead players can hear everyone
	if listener:IsSpectator() || !listener:Alive() then
		return true
	end

	-- if the player is dead or a spectator we can't hear them
	if !talker:Alive() || talker:IsSpectator() then
		return false
	end

	return true
end

function GM:PlayerCanPickupWeapon(ply, wep)
	if IsValid(wep) then
		if ply:IsProp() then
			return false
		end
	end

	return true
end
