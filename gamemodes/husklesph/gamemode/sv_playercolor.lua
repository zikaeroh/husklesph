local EntityMeta = FindMetaTable("Entity")

function EntityMeta:GetPlayerColor()
	return self.playerColor || Vector()
end

function EntityMeta:SetPlayerColor(vec)
	self.playerColor = vec
	self:SetNWVector("playerColor", vec)
end
