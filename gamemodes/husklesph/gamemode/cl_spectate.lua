net.Receive("spectating_status", function(length)
	GAMEMODE.SpectateMode = net.ReadInt(8)
	GAMEMODE.Spectating = false
	GAMEMODE.Spectatee = nil
	if GAMEMODE.SpectateMode >= 0 then
		GAMEMODE.Spectating = true
		GAMEMODE.Spectatee = net.ReadEntity()
	end

end)

function GM:IsCSpectating()
	return self.Spectating
end

function GM:GetCSpectatee()
	return self.Spectatee
end

function GM:GetCSpectateMode()
	return self.SpectateMode
end
