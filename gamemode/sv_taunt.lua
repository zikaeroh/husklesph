include("sh_taunt.lua")

util.AddNetworkString("open_taunt_menu")

concommand.Add("ph_taunt", function (ply, com, args, full)
	if !IsValid(ply) then
		return
	end

	if !ply:Alive() then return end

	if ply.Taunting && ply.Taunting > CurTime() then
		return
	end

	local snd = args[1] or ""
	if !AllowedTauntSounds[snd] then
		return
	end

	local t
	for k, v in pairs(AllowedTauntSounds[snd]) do
		if v.sex && v.sex != ply.ModelSex then
			continue
		end

		if v.team && v.team != ply:Team() then
			continue
		end

		t = v
	end

	if !t then
		return
	end

	local duration = SoundDuration(snd)
	if snd:match("%.mp3$") then
		duration = t.soundDurationOverride or 1
	end

	-- TODO: don't repeat this code everywhere.
	local sndName = string.Trim(snd)
	sndName = string.Replace(sndName, "/", "_")
	sndName = string.Replace(sndName, ".", "_")

	ply:EmitSound(sndName)
	ply.Taunting = CurTime() + duration + 0.1
	ply.TauntAmount = (ply.TauntAmount or 0) + 1

	if !ply.TauntsUsed then ply.TauntsUsed = {} end
	ply.TauntsUsed[sndName] = true
end)

concommand.Add("ph_taunt_random", function (ply, com, args, full)
	if !IsValid(ply) then
		return
	end

	if !ply:Alive() then return end

	if ply.Taunting && ply.Taunting > CurTime() then
		return
	end

	local potential = {}
	for k, v in pairs(Taunts) do
		if v.sex && v.sex != ply.ModelSex then
			continue
		end

		if v.team && v.team != ply:Team() then
			continue
		end

		table.insert(potential, v)
	end

	if #potential == 0 then 
		return
	end

	local t = potential[math.random(#potential)]
	local snd = t.sound[math.random(#t.sound)]

	local duration = SoundDuration(snd)
	if snd:match("%.mp3$") then
		duration = t.soundDurationOverride or 1
	end

	-- TODO: don't repeat this code everywhere.
	local sndName = string.Trim(snd)
	sndName = string.Replace(sndName, "/", "_")
	sndName = string.Replace(sndName, ".", "_")

	ply:EmitSound(sndName)
	ply.Taunting = CurTime() + duration + 0.1
	ply.TauntAmount = (ply.TauntAmount or 0) + 1

	if !ply.TauntsUsed then ply.TauntsUsed = {} end
	ply.TauntsUsed[sndName] = true
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
	(GM or GAMEMODE):SetTauntMenuPhrase(value_new)
end)
