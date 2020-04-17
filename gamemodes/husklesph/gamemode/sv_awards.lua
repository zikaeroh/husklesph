PlayerAwards = {}

PlayerAwards.LastPropStanding = {
	name = "Longest Survivor",
	desc = "Prop who survived longest",
	getWinner = function()
		if GAMEMODE.LastRoundResult == WIN_HUNTER then
			return GAMEMODE.LastPropDeath
		end

		return nil
	end
}

PlayerAwards.LeastMovement = {
	name = "Least Movement",
	desc = "Prop who moved the least",
	getWinner = function()
		local minPly

		for _, ply in ipairs(GAMEMODE:GetPlayingPlayers()) do
			if !ply:IsProp() then continue end

			if !minPly || ply.PropMovement < minPly.PropMovement then
				minPly = ply
			end
		end

		return minPly
	end
}

PlayerAwards.MostTaunts = {
	name = "Most Taunts",
	desc = "Prop who taunted the most",
	getWinner = function()
		local maxPly

		for _, ply in ipairs(GAMEMODE:GetPlayingPlayers()) do
			if !ply:IsProp() then continue end

			if !maxPly || ply.TauntAmount > maxPly.TauntAmount then
				maxPly = ply
			end
		end

		if maxPly && maxPly.TauntAmount > 0 then return maxPly end
		return nil
	end
}

PlayerAwards.FirstHunterKill = {
	name = "First Blood",
	desc = "Hunter who had the first kill",
	getWinner = function()
		return GAMEMODE.FirstHunterKill
	end
}

PlayerAwards.MostKills = {
	name = "Most Kills",
	desc = "Hunter who had the most kills",
	getWinner = function()
		local maxPly

		for _, ply in ipairs(GAMEMODE:GetPlayingPlayers()) do
			if !ply:IsHunter() then continue end

			if !killsPly || ply.HunterKills > maxPly.HunterKills then
				maxPly = ply
			end
		end

		if maxPly && maxPly.HunterKills > 0 then return maxPly end
		return nil
	end
}

PlayerAwards.PropDamage = {
	name = "Angriest Player",
	desc = "Hunter who shot at props the most",
	getWinner = function()
		local maxPly

		for _, ply in ipairs(GAMEMODE:GetPlayingPlayers()) do
			if !ply:IsHunter() then continue end

			if !maxPly || ply.PropDmgPenalty > maxPly.PropDmgPenalty then
				maxPly = ply
			end
		end

		if maxPly && maxPly.PropDmgPenalty > 0 then return maxPly end
		return nil
	end
}

PlayerAwards.MostMovement = {
	name = "Most Movement",
	desc = "Prop who moved the most",
	getWinner = function()
		local maxPly

		for _, ply in ipairs(GAMEMODE:GetPlayingPlayers()) do
			if !ply:IsProp() then continue end

			if !maxPly || ply.PropMovement > maxPly.PropMovement then
				maxPly = ply
			end
		end

		if maxPly && maxPly.PropMovement > 0 then return maxPly end
		return nil
	end
}
