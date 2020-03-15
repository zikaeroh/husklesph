local PlayerMeta = FindMetaTable("Player")
local EntityMeta = FindMetaTable("Entity")

function GM:PlayerInitialSpawn(ply)
	self:RoundsSetupPlayer(ply)

	self:TeamsSetupPlayer(ply)

	if self:GetGameState() != 0 then
		timer.Simple(0, function ()
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

net.Receive("clientIPE", function (len, ply)
	if !ply.ClientIPE then
		ply.ClientIPE = true
		hook.Call("PlayerLoadedLocalPlayer", GAMEMODE, ply)
	end
end)

function GM:PlayerDisconnected(ply)
	ply:SetTeam(2)
end

util.AddNetworkString("hull_set")
function GM:PlayerSpawn( ply )

	ply:UnCSpectate()

	player_manager.OnPlayerSpawn( ply )
	player_manager.RunClass( ply, "Spawn" )

	hook.Call( "PlayerLoadout", GAMEMODE, ply )
	hook.Call( "PlayerSetModel", GAMEMODE, ply )

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
	if ( IsValid( oldhands ) ) then oldhands:Remove() end

	local hands = ents.Create( "gmod_hands" )
	if ( IsValid( hands ) ) then
		ply:SetHands( hands )
		hands:SetOwner( ply )

		-- Which hands should we use?
		local cl_playermodel = ply:GetInfo( "cl_playermodel" )
		local info = player_manager.TranslatePlayerHands( cl_playermodel )
		if ( info ) then
			hands:SetModel( info.model )
			hands:SetSkin( info.skin )
			hands:SetBodyGroups( info.body )
		end

		-- Attach them to the viewmodel
		local vm = ply:GetViewModel( 0 )
		hands:AttachToViewmodel( vm )

		vm:DeleteOnRemove( hands )
		ply:DeleteOnRemove( hands )

		hands:Spawn()
 	end
end

function PlayerMeta:CalculateSpeed()
	// set the defaults
	local settings = {
		walkSpeed = 250,
		runSpeed = 50,
		jumpPower = 200,
		canRun = true,
		canMove = true,
		canJump = true
	}

	// speed penalty for small objects (popcan, small bottles, mouse, etc)
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


	// set out new speeds
	if settings.canRun then
		self:SetRunSpeed(settings.runSpeed or 1)
	else
		self:SetRunSpeed(settings.walkSpeed or 1)
	end
	if self:GetMoveType() != MOVETYPE_NOCLIP then
		if settings.canMove then
			self:SetMoveType(MOVETYPE_WALK)
		else
			self:SetMoveType(MOVETYPE_NONE)
		end
	end
	self.CanRun = settings.canRun
	self:SetWalkSpeed(settings.walkSpeed or 1)
	self:SetJumpPower(settings.jumpPower or 1)
end

function GM:PlayerLoadout(ply)
	if ply:Team() == 2 then
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


function GM:PlayerSetModel( ply )

	local cl_playermodel = ply:GetInfo( "cl_playermodel" )

	local playerModel = table.Random(playerModels)
	cl_playermodel = playerModel.model

	local modelname = player_manager.TranslatePlayerModel( cl_playermodel )
	util.PrecacheModel( modelname )
	ply:SetModel( modelname )
	ply.ModelSex = playerModel.sex

	net.Start("player_model_sex")
	net.WriteString(playerModel.sex)
	net.Send(ply)
end

function GM:PlayerDeathSound()
	return true
end

function GM:PlayerSelectSpawn( pl )

	local spawnPoints = {}


	if pl:Team() == 3 then // props
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_terrorist" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_axis" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_combine" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_pirate" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_viking" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "diprip_start_team_blue" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_blue" ) )        
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_human" ) )
	elseif pl:Team() == 2 then 
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_counterterrorist" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_allies" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_rebel" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_knight" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "diprip_start_team_red" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_red" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_zombie" ) )      
	end

	local Count = table.Count( spawnPoints )

	if pl:Team() == 1 || Count == 0 then
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_start" ) )
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "gmod_player_start" ) ) -- (Old) GMod Maps
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_teamspawn" ) ) -- TF Maps
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "ins_spawnpoint" ) ) -- INS Maps
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "aoc_spawnpoint" ) ) -- AOC Maps
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "dys_spawn_point" ) ) -- Dystopia Maps
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_coop" ) ) -- SYN Maps
		spawnPoints = table.Add( spawnPoints, ents.FindByClass( "info_player_deathmatch" ) )
	end


	// recount
	local Count = table.Count( spawnPoints )
	
	if ( Count == 0 ) then
		Msg("[PlayerSelectSpawn] Error! No spawn points!\n")
		return nil
	end
	
	local ChosenSpawnPoint = nil
	
	-- Try to work out the best, random spawnpoint
	for i = 0, Count do
	
		ChosenSpawnPoint = table.Random( spawnPoints )

		if ( ChosenSpawnPoint &&
			ChosenSpawnPoint:IsValid() &&
			ChosenSpawnPoint:IsInWorld() &&
			ChosenSpawnPoint != pl:GetVar( "LastSpawnpoint" ) &&
			ChosenSpawnPoint != self.LastSpawnPoint ) then
			
			if ( hook.Call( "IsSpawnpointSuitable", GAMEMODE, pl, ChosenSpawnPoint, i == Count ) ) then
			
				self.LastSpawnPoint = ChosenSpawnPoint
				pl:SetVar( "LastSpawnpoint", ChosenSpawnPoint )
				return ChosenSpawnPoint
			
			end
			
		end
			
	end
	
	return ChosenSpawnPoint
	
end

function GM:PlayerDeathThink(ply)
	if self:CanRespawn(ply) then
		ply:Spawn()
	else
		self:ChooseSpectatee(ply)
	end
end

local defaultDeathsound = Sound("ambient/voices/f_scream1.wav")
local deathsoundsFile = file.Read(GM.Folder .. "/ph_deathsounds.txt", "GAME") or ""
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
	return chooseDeathsound(ply:SteamID()) or chooseDeathsound("default") or defaultDeathsound
end

function GM:DoPlayerDeath(ply, attacker, dmginfo)
	if ply:IsDisguised() && ply:Team() == 3 then
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

	// are they a prop
	if ply:Team() == 3 then
		// set the last death award
		self.LastPropDeath = ply
	end
	ply:UnDisguise()

	ply:Freeze(false) // why?, *sigh*
	
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

			// did a hunter kill a prop
			if attacker:Team() == 2 && ply:Team() == 3 then

				// increase their round kills
				attacker.HunterKills = (attacker.HunterKills or 0) + 1

				// set the first hunter kill award
				if self.FirstHunterKill == nil then
					self.FirstHunterKill = attacker
				end
			end
		end
	end

	self:AddKillFeed(ply, attacker, dmginfo)
end

function GM:PlayerDeath(ply, inflictor, attacker )

	ply.NextSpawnTime = CurTime() + 1
	ply.DeathTime = CurTime()

	// time until player can spectate another player
	ply.SpectateTime = CurTime() + 2

end

function GM:KeyPress(ply, key)
	if ply:Alive() then
		if key == IN_ATTACK then
			self:PlayerDisguise(ply)
		elseif key == IN_ATTACK2 then
		end
	end
end

function GM:PlayerSwitchFlashlight(ply)
	if ply:IsDisguised() then
		return false
	end
	return true
end

function GM:PlayerShouldTaunt( ply, actid )
	return false
end

function GM:PlayerCanSeePlayersChat( text, teamOnly, listener, speaker )
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


local sv_alltalk = GetConVar( "sv_alltalk" )
function GM:PlayerCanHearPlayersVoice( listener, talker ) 
	if !IsValid(talker) then return false end
	return self:PlayerCanHearChatVoice(listener, talker, "voice") 
end


function GM:PlayerCanHearChatVoice( listener, talker, typ, teamOnly )
	if typ == "chat" && teamOnly then
		if listener:Team() != talker:Team() then
			return false
		end
	end

	if sv_alltalk:GetBool() then
		return true
	end
	
	if self:GetGameState() == 3 || self:GetGameState() == 0 then
		return true
	end

	// spectators and dead players can hear everyone
	if listener:Team() == 1 || !listener:Alive() then
		return true
	end

	// if the player is dead or a spectator we can't hear them
	if !talker:Alive() || talker:Team() == 1 then
		return false
	end

	return true

end

function GM:PlayerCanPickupWeapon(ply, wep)
	if IsValid(wep) then
		if ply:Team() == 3 then
			return false
		end
	end
	return true
end