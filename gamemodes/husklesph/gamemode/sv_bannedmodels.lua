-- This file is what controls what models are banned. Models that are banned
-- cannot be chosen as a disguise.

GM.BannedModels = {} -- This is used as a hash table where the key is the model string and the value is true.

util.AddNetworkString("ph_bannedmodels_getall")
util.AddNetworkString("ph_bannedmodels_add")
util.AddNetworkString("ph_bannedmodels_remove")

function GM:IsModelBanned(model)
	return self.BannedModels[model] == true
end

function GM:AddBannedModel(model)
	if self.BannedModels[model] == true then return end

	self.BannedModels[model] = true
	self:SaveBannedModels()
end

function GM:RemoveBannedModel(model)
	if self.BannedModels[model] != true then return end

	self.BannedModels[model] = nil
	self:SaveBannedModels()
end

function GM:SaveBannedModels()
	-- ensure the folders are there
	if !file.Exists("husklesph/", "DATA") then
		file.CreateDir("husklesph")
	end

	local txt = ""
	for key, value in pairs(self.BannedModels) do
		if value then
			txt = txt .. key .. "\r\n"
		end
	end

	file.Write("husklesph/bannedmodels.txt", txt)
end

function GM:LoadBannedModels()
	local bannedModels = file.Read("husklesph/bannedmodels.txt", "DATA")
	if bannedModels then
		for match in bannedModels:gmatch("[^\r\n]+") do
			self:AddBannedModel(match)
		end
	end
end

net.Receive("ph_bannedmodels_getall", function(len, ply)
	net.Start("ph_bannedmodels_getall")

	for key, value in pairs(GAMEMODE.BannedModels) do
		if value then
			net.WriteString(key)
		end
	end

	net.WriteString("")
	net.Send(ply)
end)

net.Receive("ph_bannedmodels_add", function(len, ply)
	if !ply:IsAdmin() then return end

	local model = net.ReadString()
	if model == "" then return end

	GAMEMODE:AddBannedModel(model)
	net.Start("ph_bannedmodels_add")
	net.WriteString(model)
	net.Broadcast()
end)

net.Receive("ph_bannedmodels_remove", function(len, ply)
	if !ply:IsAdmin() then return end

	local model = net.ReadString()
	if model == "" then return end

	GAMEMODE:RemoveBannedModel(model)
	net.Start("ph_bannedmodels_remove")
	net.WriteString(model)
	net.Broadcast()
end)
