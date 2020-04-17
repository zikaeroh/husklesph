function GM:CanRespawn(ply)
	if ply:IsSpectator() then
		return false
	end

	if self:GetGameState() == ROUND_WAIT then
		if ply.NextSpawnTime && ply.NextSpawnTime > CurTime() then return end

		if ply:KeyPressed(IN_JUMP) || ply:KeyPressed(IN_ATTACK) then
			return true
		end
	end

	return false
end
