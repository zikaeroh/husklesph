-- last prop death award
local function lastPropStandingCalcuation()
	if GAMEMODE.LastRoundResult == WIN_HUNTER then
		return GAMEMODE.LastPropDeath
	end

	return nil
end


-- get prop with least movement
local function leastMovementCalcuation()
	local minPly

	for _, ply in ipairs(GAMEMODE:GetPlayingPlayers()) do
		if !ply:IsProp() then continue end

		if !minPly || ply.PropMovement < minPly.PropMovement then
			minPly = ply
		end
	end

	return minPly
end


-- get prop with most taunts
local function mostTauntsCalcuation()
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


-- first hunter kill award
local function firstHunterKillCalcuation()
	return GAMEMODE.FirstHunterKill
end


-- get hunter with most kills
local function mostKillsCalcuation()
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


-- get hunter with most prop damage
local function propDamageCalcuation()
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


-- get prop with most movement
local function mostMovementCalcuation()
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


PlayerAwardsTemplate = {
	LastPropStanding = {
		name = "Longest Survivor",
		desc = "Prop who survived longest",
		getWinner = lastPropStandingCalcuation
	},
	LeastMovement = {
		name = "Least Movement",
		desc = "Prop who moved the least",
		getWinner = leastMovementCalcuation
	},
	MostTaunts = {
		name = "Most Taunts",
		desc = "Prop who taunted the most",
		getWinner = mostTauntsCalcuation
	},
	FirstHunterKill = {
		name = "First Blood",
		desc = "Hunter who had the first kill",
		getWinner = firstHunterKillCalcuation
	},
	MostKills = {
		name = "Most Kills",
		desc = "Hunter who had the most kills",
		getWinner = mostKillsCalcuation
	},
	PropDamage = {
		name = "Angriest Player",
		desc = "Hunter who shot at props the most",
		getWinner = propDamageCalcuation
	},
	MostMovement = {
		name = "Most Movement",
		desc = "Prop who moved the most",
		getWinner = mostMovementCalcuation
	}
}
