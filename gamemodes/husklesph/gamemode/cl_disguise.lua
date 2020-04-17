include("sh_disguise.lua")

local PlayerMeta = FindMetaTable("Player")

function PlayerMeta:IsDisguised()
	return self:GetNWBool("disguised", false)
end

local function renderDis(self)
	for k, ply in pairs(player.GetAll()) do
		if ply:Alive() && ply:IsDisguised() then
			local model = ply:GetNWString("disguiseModel")
			if model && model != "" then
				local ent = ply:GetNWEntity("disguiseEntity")
				if IsValid(ent) then
					local mins = ply:GetNWVector("disguiseMins")
					local maxs = ply:GetNWVector("disguiseMaxs")
					local ang = ply:EyeAngles()
					ang.p = 0
					ang.r = 0
					if ply:DisguiseRotationLocked() then
						ang.y = ply:GetNWFloat("disguiseRotationLockYaw")
					end
					local pos = ply:GetPos() + Vector(0, 0, -mins.z)
					local center = (maxs + mins) / 2
					center.z = 0
					center:Rotate(ang)
					ent:SetPos(pos - center)
					ent:SetAngles(ang)
					ent:SetSkin(ply:GetNWInt("disguiseSkin", 1))
				end
			end
		end
	end
end

function GM:RenderDisguises()
	cam.Start3D(EyePos(), EyeAngles())
	local b, err = pcall(renderDis, self)
	cam.End3D()
	if !b then
		MsgC(Color(255, 0, 0), err .. "\n")
	end
end

function GM:RenderDisguiseHalo()
	local client = LocalPlayer()
	if client:IsProp() then
		local canDisguise, target = self:PlayerCanDisguiseCurrentTarget(client)
		if canDisguise then
			local col = Color(50, 220, 50)
			local hullxy, hullz = target:GetPropSize()
			if !client:CanFitHull(hullxy, hullxy, hullz) then
				col = Color(220, 50, 50)
			end
			halo.Add({target}, col, 2, 2, 2, true, true)
		end

		local tab = {}
		for k, ply in pairs(player.GetAll()) do
			if ply != client && ply:IsProp() && ply:IsDisguised() then
				if IsValid(ply.PropMod) then
					table.insert(tab, ply.PropMod)
				end
			end
		end
		halo.Add(tab, team.GetColor(TEAM_PROP), 2, 2, 2, true, false)
	end
end
