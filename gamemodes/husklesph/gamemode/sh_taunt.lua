Taunts = {}
TauntCategories = {}
AllowedTauntSounds = {}
TauntMenuPhrase = "make annoying fart sounds"

function FilenameToSoundname(filename)
	local sndName = string.Trim(filename)
	sndName = string.Replace(sndName, "/", "_")
	return string.Replace(sndName, ".", "_")
end

function PlayerModelTauntAllowed(ply, whitelist)
	if whitelist == nil then return true end

	local mod = ply:GetModel()
	mod = player_manager.TranslateToPlayerModelName(mod)
	local models = player_manager.AllValidModels()
	for _, v in pairs(whitelist) do
		if !models[v] then
			-- v was not a name, so check it as a path
			v = string.lower(v)
			v = player_manager.TranslateToPlayerModelName(v)
		end

		if mod == v then return true end
	end

	return false
end

local function teamNameToNum(pteam)
	pteam = pteam:lower()
	if pteam == "prop" || pteam == "props" then
		return TEAM_PROP
	elseif pteam == "hunter" || pteam == "hunters" then
		return TEAM_HUNTER
	end
	return nil
end

local function teamNameTableToNumTable(pteams)
	local ret = {}
	for i, pteam in ipairs(pteams) do
		ret[i] = teamNameToNum(pteam)
	end
	return ret
end

function TauntAllowedForPlayer(ply, tauntTable)
	if tauntTable.sex then
		if GAMEMODE && GAMEMODE.PlayerModelSex then
			if tauntTable.sex != GAMEMODE.PlayerModelSex then
				return false
			end
		elseif tauntTable.sex != ply.ModelSex then
			return false
		end
	end

	if type(tauntTable.team) == "table" then
		if !table.HasValue(tauntTable.team, ply:Team()) then
			return false
		end
	elseif tauntTable.team != ply:Team() then
		return false
	end

	return PlayerModelTauntAllowed(ply, tauntTable.allowedModels)
end

-- display name, table of sound files, team (name or id), sex (nil for both), table of category ids, [duration in seconds]
local function addTaunt(name, snd, pteam, sex, cats, duration, allowedModels)
	if !name || type(name) != "string" then return end
	if type(snd) != "table" then snd = {tostring(snd)} end
	if #snd == 0 then error("No sounds for " .. name) return end

	local t = {}
	t.sound = snd
	t.categories = cats
	if type(pteam) == "string" then
		t.team = teamNameToNum(pteam)
	elseif type(pteam) == "table" then
		t.team = teamNameTableToNumTable(pteam)
	else
		t.team = tonumber(pteam)
	end

	if sex && #sex > 0 then
		t.sex = sex
		if sex == "both" || sex == "nil" then
			t.sex = nil
		end
	end

	t.name = name
	t.allowedModels = allowedModels

	local dur, count = 0, 0
	for k, v in pairs(snd) do
		sound.Add({
			name = FilenameToSoundname(v),
			channel = CHAN_AUTO,
			level = 75,
			sound = v
		})

		if !AllowedTauntSounds[v] then AllowedTauntSounds[v] = {} end
		table.insert(AllowedTauntSounds[v], t)
		dur = dur + SoundDuration(v)
		count = count + 1

		if SERVER then
			-- network the taunt
			resource.AddFile("sound/" .. v)
		end
	end

	t.soundDuration = dur / count
	if tonumber(duration) then
		t.soundDuration = tonumber(duration)
		t.soundDurationOverride = tonumber(duration)
	end

	table.insert(Taunts, t)
	if cats then
		for k, cat in pairs(cats) do
			if !TauntCategories[cat] then TauntCategories[cat] = {} end
			table.insert(TauntCategories[cat], t)
		end
	end
end

local tempG = {}
tempG.addTaunt = addTaunt

-- inherit from _G
local meta = {}
meta.__index = _G
meta.__newindex = _G
setmetatable(tempG, meta)

local function loadTaunts(rootFolder)
	local files = file.Find(rootFolder .. "*.lua", "LUA")
	for k, v in pairs(files) do
		local filePath = rootFolder .. v
		AddCSLuaFile(filePath)

		local f = CompileFile(filePath)
		if !f then
			return
		end

		setfenv(f, tempG)
		local b, err = pcall(f)

		local s = SERVER && "Server" || "Client"
		local c = SERVER && 90 || 0
		if !b then
			MsgC(Color(255, 50, 50 + c), s .. " loading taunts failed: " .. filePath .. "\nError: " .. err .. "\n")
		else
			MsgC(Color(50, 255, 50 + c), s .. " loaded taunts file: " .. filePath .. "\n")
		end
	end
end

function GM:LoadTaunts()
	loadTaunts((GM || GAMEMODE).Folder:sub(11) .. "/gamemode/taunts/")
	loadTaunts("husklesph/taunts/")
end

GM:LoadTaunts()
