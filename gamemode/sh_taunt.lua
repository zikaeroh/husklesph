

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
	print("mod", mod)

	local models = player_manager.AllValidModels()

	for _, v in pairs(whitelist) do
		print("v", v)

		if !models[v] then
			-- v was not a name, so check it as a path
			v = string.lower(v)
			v = player_manager.TranslateToPlayerModelName(v)
			print("checking path, v", v)
		end

		if mod == v then return true end
	end

	return false
end

// display name, table of sound files, team (name or id), sex (nil for both), table of category ids, [duration in seconds]
local function addTaunt(name, snd, pteam, sex, cats, duration, allowedModels)
	if !name || type(name) != "string" then return end
	if type(snd) != "table" then snd = {tostring(snd)} end
	if #snd == 0 then error("No sounds for " .. name) return end

	local t = {}
	t.sound = snd
	t.categories = cats
	if type(pteam) == "string" then
		pteam = pteam:lower()
		if pteam == "prop" || pteam == "props" then
			t.team = 3
		elseif pteam == "hunter" || pteam == "hunters" then
			t.team = 2
		end
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
			// network the taunt
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

// inherit from _G
local meta = {}
meta.__index = _G
meta.__newindex = _G
setmetatable(tempG, meta)

local function loadTaunts(rootFolder)
	local files, dirs = file.Find(rootFolder .. "*.lua", "LUA")
	for k, v in pairs(files) do
		local filePath = rootFolder .. v
		AddCSLuaFile(filePath)

		local f = CompileFile(filePath)
		if !f then
			return
		end
		setfenv(f, tempG)
		local b, err = pcall(f)

		local s = SERVER and "Server" or "Client"
		local c = SERVER and 90 or 0
		if !b then
			MsgC(Color(255, 50, 50 + c), s .. " loading taunts failed: " .. filePath .. "\nError: " .. err .. "\n")
		else
			MsgC(Color(50, 255, 50 + c), s .. " loaded taunts file: " .. filePath .. "\n")
		end
	end
end

function GM:LoadTaunts()
	loadTaunts((GM or GAMEMODE).Folder:sub(11) .. "/gamemode/taunts/")
	loadTaunts("husklesph/taunts/")
end

GM:LoadTaunts()