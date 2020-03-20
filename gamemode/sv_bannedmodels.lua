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
	if self.BannedModels[model] == true then return end -- Prevent duplicates.

	self.BannedModels[model] = true
	self:SaveBannedModels()
end


function GM:RemoveBannedModel(model)
	if self.BannedModels[model] != true then return end -- Check if exists before trying to remove.

	self.BannedModels[model] = nil
	self:SaveBannedModels()
end


function GM:SaveBannedModels()
	-- ensure the folders are there
	if !file.Exists("husklesph/","DATA") then
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
	local banned_models = file.Read("husklesph/bannedmodels.txt", "DATA")
	if banned_models then
		local tbl = {}
		for match in banned_models:gmatch("[^\r\n]+") do
			self:AddBannedModel(match)
		end
	end
end


net.Receive("ph_bannedmodels_getall", function (len, ply)
	-- This section is to prevent this particular net.Receive from going into an infinite loop.
	if ply.PHBannedModelsGetAllCooldown != nil && ply.PHBannedModelsGetAllCooldown > CurTime() then return end
	ply.PHBannedModelsGetAllCooldown = CurTime() + 0.1

	net.Start("ph_bannedmodels_getall")

	for key, value in pairs(GAMEMODE.BannedModels) do
		if value then
			net.WriteString(key)
		end
	end

	net.WriteString("")
	net.Send(ply)
end)


net.Receive("ph_bannedmodels_add", function (len, ply)
	-- This section is to prevent this particular net.Receive from going into an infinite loop.
	if ply.PHBannedModelsAddCooldown != nil && ply.PHBannedModelsAddCooldown > CurTime() then return end
	ply.PHBannedModelsAddCooldown = CurTime() + 0.1

	if !ply:IsAdmin() then return end -- Only admins can change the banned models list.

	local model_to_ban = net.ReadString()
	if string.len(model_to_ban) == 0 then return end -- Don't add empty strings.

	GAMEMODE:AddBannedModel(model_to_ban)
	net.Start("ph_bannedmodels_add")
	net.WriteString(model_to_ban)
	net.Broadcast()
end)


net.Receive("ph_bannedmodels_remove", function (len, ply)
	-- This section is to prevent this particular net.Receive from going into an infinite loop.
	if ply.PHBannedModelsRemoveCooldown != nil && ply.PHBannedModelsRemoveCooldown > CurTime() then return end
	ply.PHBannedModelsRemoveCooldown = CurTime() + 0.1

	if !ply:IsAdmin() then return end -- Only admins can change the banned models list.

	local model_to_unban = net.ReadString()
	if string.len(model_to_unban) == 0 then return end -- Don't try to remove empty strings.

	GAMEMODE:RemoveBannedModel(model_to_unban)
	net.Start("ph_bannedmodels_remove")
	net.WriteString(model_to_unban)
	net.Broadcast()
end)
