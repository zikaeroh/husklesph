include("sh_taunt.lua")

util.AddNetworkString("open_taunt_menu")

local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:CanTaunt()
	if !self:Alive() then
		return false
	end

	if self.TauntEnd && self.TauntEnd > CurTime() then
		return false
	end

	return true
end

function PlayerMeta:EmitTaunt(filename, durationOverride)
	local duration = SoundDuration(filename)
	if filename:match("%.mp3$") then
		duration = durationOverride || 1
	end

	local sndName = FilenameToSoundname(filename)

	self:EmitSound(sndName)
	self.TauntEnd = CurTime() + duration + 0.1
	self.TauntAmount = (self.TauntAmount || 0) + 1
	self.AutoTauntDeadline = nil

	if !self.TauntsUsed then self.TauntsUsed = {} end
	self.TauntsUsed[sndName] = true
end

local function ForEachTaunt(ply, taunts, func)
	for k, v in pairs(taunts) do
		if !TauntAllowedForPlayer(ply, v) then continue end

		if func(k, v) then return end
	end
end

local function DoTaunt(ply, snd)
	if !IsValid(ply) then return end
	if !ply:CanTaunt() then return end

	local ats = AllowedTauntSounds[snd]
	if !ats then return end

	local t
	ForEachTaunt(ply, ats, function(k, v)
		t = v
		return true
	end)

	if !t then
		return
	end

	ply:EmitTaunt(snd, t.soundDurationOverride)
end

local function DoRandomTaunt(ply)
	if !IsValid(ply) then return end
	if !ply:CanTaunt() then return end

	local potential = {}
	ForEachTaunt(ply, Taunts, function(k, v)
		table.insert(potential, v)
	end)

	if #potential == 0 then return end

	local t = potential[math.random(#potential)]
	local snd = t.sound[math.random(#t.sound)]

	ply:EmitTaunt(snd, t.soundDurationOverride)
end

concommand.Add("ph_taunt", function(ply, com, args, full)
	DoTaunt(ply, args[1] || "")
end)

concommand.Add("ph_taunt_random", function(ply, com, args, full)
	DoRandomTaunt(ply)
end)

util.AddNetworkString("ph_set_taunt_menu_phrase")
function GM:SetTauntMenuPhrase(phrase, ply)
	net.Start("ph_set_taunt_menu_phrase")
	net.WriteString(phrase)

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

cvars.AddChangeCallback("ph_taunt_menu_phrase", function(convar_name, value_old, value_new)
	(GM || GAMEMODE):SetTauntMenuPhrase(value_new)
end)

function GM:AutoTauntCheck()
	if self.GameState != ROUND_SEEK then return end

	local propsOnly = self.AutoTauntPropsOnly:GetBool()
	local minDeadline = self.AutoTauntMin:GetInt()
	local maxDeadline = self.AutoTauntMax:GetInt()
	local badMinMax = minDeadline <= 0 || maxDeadline <= 0 || minDeadline > maxDeadline

	for i, ply in ipairs(player.GetAll()) do
		if propsOnly && !ply:IsProp() then
			ply.AutoTauntDeadline = nil
			continue
		end

		local begin
		if ply.AutoTauntDeadline then
			local secsLeft = ply.AutoTauntDeadline - CurTime()
			if secsLeft > 0 then
				continue
			end

			if !ply.TauntEnd || CurTime() > ply.AutoTauntDeadline then
				DoRandomTaunt(ply)
				begin = ply.TauntEnd
			end
		end
		if !begin then begin = CurTime() end

		if badMinMax then continue end

		local delta = math.random(minDeadline, maxDeadline)
		ply.AutoTauntDeadline = begin + delta
	end
end

function GM:StartAutoTauntTimer()
	timer.Remove("AutoTauntCheck")
	local start = self.AutoTauntEnabled:GetBool()

	if start then
		timer.Create("AutoTauntCheck", 5, 0, function()
			self:AutoTauntCheck()
		end)
	end
end

cvars.AddChangeCallback("ph_auto_taunt", function(convar_name, value_old, value_new)
	(GM || GAMEMODE):StartAutoTauntTimer()
end)
