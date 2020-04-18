-- mapvote

util.AddNetworkString("ph_mapvote")
util.AddNetworkString("ph_mapvotevotes")

GM.MapVoteTime = GAMEMODE && GAMEMODE.MapVoteTime || 30
GM.MapVoteStart = GAMEMODE && GAMEMODE.MapVoteStart || CurTime()

function GM:IsMapVoting()
	return self.MapVoting
end

function GM:GetMapVoteStart()
	return self.MapVoteStart
end

function GM:GetMapVoteRunningTime()
	return CurTime() - self.MapVoteStart
end

function GM:RotateMap()
	local map = game.GetMap()
	local index
	for k, map2 in pairs(self.MapList) do
		if map == map2 then
			index = k
		end
	end

	if !index then index = 1 end
	index = index + 1

	if index > #self.MapList then
		index = 1
	end

	local nextMap = self.MapList[index]
	self:ChangeMapTo(nextMap)
end

function GM:ChangeMapTo(map)
	if map == game.GetMap() then
		self.Rounds = 0
		self:SetGameState(ROUND_WAIT)
		return
	end

	print("[husklesph] Rotate changing map to " .. map)
	GlobalChatMsg("Changing map to ", map)
	hook.Call("OnChangeMap", GAMEMODE)
	timer.Simple(5, function()
		RunConsoleCommand("changelevel", map)
	end)
end

GM.MapList = {}

local defaultMapList = {
	"cs_italy",
	"cs_office",
	"cs_compound",
	"cs_assault"
}

function GM:SaveMapList()
	-- ensure the folders are there
	if !file.Exists("husklesph/", "DATA") then
		file.CreateDir("husklesph")
	end

	local txt = ""
	for k, map in pairs(self.MapList) do
		txt = txt .. map .. "\r\n"
	end

	file.Write("husklesph/maplist.txt", txt)
end

function GM:LoadMapList()
	local jason = file.ReadDataAndContent("husklesph/maplist.txt")
	if jason then
		local tbl = {}
		for map in jason:gmatch("[^\r\n]+") do
			table.insert(tbl, map)
		end

		self.MapList = tbl
	else
		local tbl = {}

		for k, map in pairs(defaultMapList) do
			if file.Exists("maps/" .. map .. ".bsp", "GAME") then
				table.insert(tbl, map)
			end
		end

		local files = file.Find("maps/*", "GAME")
		for k, v in pairs(files) do
			local name = v:match("([^%.]+)%.bsp$")
			if name then
				if name:sub(1, 3) == "ph_" then
					table.insert(tbl, name)
				end
			end
		end

		self.MapList = tbl
		self:SaveMapList()
	end

	for k, map in pairs(self.MapList) do
		local path = "maps/" .. map .. ".png"
		if file.Exists(path, "GAME") then
			resource.AddSingleFile(path)
		else
			local path = "maps/thumb/" .. map .. ".png"
			if file.Exists(path, "GAME") then
				resource.AddSingleFile(path)
			end
		end
	end
end

function GM:StartMapVote()
	-- Check if we're using the MapVote addon. If so, ignore the builtin mapvote logic.
	-- MapVote Workshop Link: https://steamcommunity.com/sharedfiles/filedetails/?id=151583504
	local initHookTbl = hook.GetTable().Initialize
	if initHookTbl && initHookTbl.MapVoteConfigSetup then
		self:SetGameState(ROUND_MAPVOTE)
		MapVote.Start()
		return
	end

	self.MapVoteStart = CurTime()
	self.MapVoteTime = 30
	self.MapVoting = true
	self.MapVotes = {}

	-- randomise the order of maps so people choose different ones
	local maps = {}
	for k, v in pairs(self.MapList) do
		table.insert(maps, math.random(#maps) + 1, v)
	end

	self.MapList = maps
	self:SetGameState(ROUND_MAPVOTE)
	self:NetworkMapVoteStart()
end

function GM:MapVoteThink()
	if self.MapVoting then
		if self:GetMapVoteRunningTime() >= self.MapVoteTime then
			self.MapVoting = false
			local votes = {}
			for ply, map in pairs(self.MapVotes) do
				if IsValid(ply) && ply:IsPlayer() then
					votes[map] = (votes[map] || 0) + 1
				end
			end

			local maxvotes = 0
			for k, v in pairs(votes) do
				if v > maxvotes then
					maxvotes = v
				end
			end

			local maps = {}
			for k, v in pairs(votes) do
				if v == maxvotes then
					table.insert(maps, k)
				end
			end

			if #maps > 0 then
				self:ChangeMapTo(table.Random(maps))
			else
				GlobalChatMsg("Map change failed, not enough votes")
				print("Map change failed, not enough votes")
				self:SetGameState(ROUND_WAIT)
			end
		end
	end
end

function GM:NetworkMapVoteStart(ply)
	net.Start("ph_mapvote")
	net.WriteFloat(self.MapVoteStart)
	net.WriteFloat(self.MapVoteTime)

	for k, map in pairs(self.MapList) do
		net.WriteUInt(k, 16)
		net.WriteString(map)
	end
	net.WriteUInt(0, 16)

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end

	self:NetworkMapVotes()
end

function GM:NetworkMapVotes(ply)
	net.Start("ph_mapvotevotes")

	for k, map in pairs(self.MapVotes) do
		net.WriteUInt(1, 8)
		net.WriteEntity(k)
		net.WriteString(map)
	end
	net.WriteUInt(0, 8)

	if ply then
		net.Send(ply)
	else
		net.Broadcast()
	end
end

concommand.Add("ph_votemap", function(ply, com, args)
	if GAMEMODE.MapVoting then
		if #args < 1 then
			return
		end

		local found
		for k, v in pairs(GAMEMODE.MapList) do
			if v:lower() == args[1]:lower() then
				found = v
				break
			end
		end

		if !found then
			ply:ChatPrint("Invalid map " .. args[1])
			return
		end

		GAMEMODE.MapVotes[ply] = found
		GAMEMODE:NetworkMapVotes()
	end
end)
