local tabFile = file.Read(GM.Folder .. "/husklesph.txt", "GAME") or ""
local tab = util.KeyValuesToTable(tabFile)

GM.Name 	= tab["title"] or "Prop Hunters - Huskles Edition"
GM.Author 	= "Zikaeroh, MechanicalMind"
// Credits to waddlesworth for the logo and icon
GM.Email 	= "N/A"
GM.Website 	= "N/A"
GM.Version  = tab["version"] or "unknown"

GM.StartWaitTime = CreateConVar("ph_mapstartwait", 30, bit.bor(FCVAR_NOTIFY, FCVAR_REPLICATED), "Number of seconds to wait for players on map start before starting round" )

team.SetUp(1, "Spectators", Color(120, 120, 120))
team.SetUp(2, "Hunters", Color(255, 150, 50))
team.SetUp(3, "Props", Color(50, 150, 255))

function GM:PlayerSetNewHull(ply, s, hullz, duckz)
	self:PlayerSetHull(ply, s, s, hullz, duckz)
end

function GM:PlayerSetHull(ply, hullx, hully, hullz, duckz)
	hullx = hullx or 16
	hully = hully or 16
	hullz = hullz or 72
	duckz = duckz or hullz / 2
	ply:SetHull(Vector(-hullx, -hully, 0), Vector(hullx, hully, hullz))
	ply:SetHullDuck(Vector(-hullx, -hully, 0), Vector(hullx, hully, duckz))

	if SERVER then
		net.Start("hull_set")
		net.WriteEntity(ply)
		net.WriteFloat(hullx)
		net.WriteFloat(hully)
		net.WriteFloat(hullz)
		net.WriteFloat(duckz)
		net.Broadcast()
		// TODO send on player spawn
	end
end