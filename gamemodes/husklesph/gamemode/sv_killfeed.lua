util.AddNetworkString("ph_kill_feed_add")

local DMG_CLUB_GENERIC = bit.bor(DMG_CLUB, DMG_GENERIC)
local DMG_SLOWBURN_BURN = bit.bor(DMG_SLOWBURN, DMG_BURN)
local DMG_BLAST_SURFACE_BLAST = bit.bor(DMG_BLAST_SURFACE, DMG_BLAST)
local DMG_SONIC_SHOCK = bit.bor(DMG_SONIC, DMG_SHOCK)
local DMG_PLASMA_ENERGYBEAM = bit.bor(DMG_PLASMA, DMG_ENERGYBEAM)
local DMG_NERVEGAS_POISON = bit.bor(DMG_NERVEGAS, DMG_POISON)
local DMG_DISSOLVE_ACID = bit.bor(DMG_DISSOLVE, DMG_ACID)

local attackedMessages = {}
attackedMessages[DMG_CLUB_GENERIC] = {"killed", "destroyed"}
attackedMessages[DMG_CRUSH] = {"threw a prop at", "crushed"}
attackedMessages[DMG_BULLET] = {"shot", "fed lead to"}
attackedMessages[DMG_SLASH] = {"cut", "sliced"}
attackedMessages[DMG_SLOWBURN_BURN] = {"incinerated", "cooked"}
attackedMessages[DMG_VEHICLE] = {"ran over", "flattened"}
attackedMessages[DMG_FALL] = {"pushed", "tripped"}
attackedMessages[DMG_BLAST_SURFACE_BLAST] = {"blew up", "blasted"}
attackedMessages[DMG_SONIC_SHOCK] = {"electrocuted", "zapped"}
attackedMessages[DMG_PLASMA_ENERGYBEAM] = {"atomized", "disintegrated"}
attackedMessages[DMG_DROWN] = {"drowned"}
attackedMessages[DMG_NERVEGAS_POISON] = {"poisoned"}
attackedMessages[DMG_RADIATION] = {"irradiated"}
attackedMessages[DMG_DISSOLVE_ACID] = {"dissolved"}
attackedMessages[DMG_DIRECT] = {"mysteriously killed"}
attackedMessages[DMG_BUCKSHOT] = {"swiss cheesed", "shotgunned"}
attackedMessages[DMG_AIRBOAT] = {"shot too many props"} -- Used for indicating a hunter shot too many props

local suicideMessages = {}
suicideMessages[DMG_CLUB_GENERIC] = {"couldn't take it anymore", "killed themself"}
suicideMessages[DMG_CRUSH] = {"was crushed to death"}
suicideMessages[DMG_BULLET] = {"shot themself"}
suicideMessages[DMG_SLASH] = {"got a paper cut"}
suicideMessages[DMG_SLOWBURN_BURN] = {"burned to death"}
suicideMessages[DMG_VEHICLE] = {"ran themself over"}
suicideMessages[DMG_FALL] = {"fell over"}
suicideMessages[DMG_BLAST_SURFACE_BLAST] = {"blew themself up"}
suicideMessages[DMG_SONIC_SHOCK] = {"electrocuted themself"}
suicideMessages[DMG_PLASMA_ENERGYBEAM] = {"looked into a laser"}
suicideMessages[DMG_DROWN] = {"drowned", "couldn't swim"}
suicideMessages[DMG_NERVEGAS_POISON] = {"ate some hemlock", "couldn't find an antidote"}
suicideMessages[DMG_RADIATION] = {"handled too much uranium"}
suicideMessages[DMG_DISSOLVE_ACID] = {"spilled acid on themself"}
suicideMessages[DMG_DIRECT] = {"mysteriously died"}
suicideMessages[DMG_BUCKSHOT] = {"shotgunned themself"}
suicideMessages[DMG_AIRBOAT] = {"shot too many props"} -- Used for indicating a hunter shot too many props

local function getKillMessage(dmgInfo, tblToUse)
	local message
	for dmgType, messages in pairs(tblToUse) do
		if dmgInfo:IsDamageType(dmgType) then
			message = table.Random(messages)
		end
	end

	return message
end

function GM:AddKillFeed(ply, attacker, dmgInfo)
	local killData = {
		victimName = ply:Nick(),
		victimColor = team.GetColor(ply:Team()),
		messageColor = Color(255, 255, 255, 255)
	}

	if IsValid(attacker) && attacker:IsPlayer() && ply != attacker then
		killData.attackerName = attacker:Nick()
		killData.attackerColor = team.GetColor(attacker:Team())
		killData.message = getKillMessage(dmgInfo, attackedMessages) || "killed"
	else
		killData.message = getKillMessage(dmgInfo, suicideMessages) || "died"
	end

	net.Start("ph_kill_feed_add")
	net.WriteTable(killData)
	net.Broadcast()
end
