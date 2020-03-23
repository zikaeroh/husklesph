local url = "https://raw.githubusercontent.com/zikaeroh/husklesph/master/husklesph.txt"
local downloadlinks = "https://steamcommunity.com/sharedfiles/filedetails/?id=1585255351"


function GM:CheckForNewVersion(ply)
	local req = {}
	req.url = url
	req.failed = function (reason)
		print("Couldn't get version file.", reason)
	end
	req.success = function (code, body, headers)
		local tab = util.KeyValuesToTable(body)
		if !tab || !tab.version then
			print("Couldn't parse version file.")
			return
		end

		local msg = {}
		if tab.version != GAMEMODE.Version then
			msg = {Color(215, 20, 20), "Out of date!\n",
					Color(255, 222, 102), "You're on version ",
					Color(0, 255, 0), (GAMEMODE.Version or "error"),
					Color(255, 222, 102), " but the latest is ",
					Color(0, 255, 0), tab.version, "\n",
					Color(255, 222, 102), "Download the latest version from: ",
					Color(11, 191, 227), downloadlinks}
		else
			msg = {Color(0, 255, 0), "Up to date!"}
		end

		if IsValid(ply) then
			ply:ChatMsg(unpack(msg))
		else
			MsgC(unpack(msg))
			MsgC("\n")
		end
	end
	HTTP(req)
end

concommand.Add("ph_version", function (ply)
	local msg = {Color(255, 149, 129),
					(GAMEMODE.Name or "") ..
					" by Zikaeroh, " ..
					tostring(GAMEMODE.Version or "error") ..
					" (originally by MechanicalMind)"}

	if IsValid(ply) then
		ply:ChatMsg(unpack(msg))
	else
		MsgC(unpack(msg)) -- Print to the server console
		MsgC("\n")
	end
	GAMEMODE:CheckForNewVersion(ply)
end)
