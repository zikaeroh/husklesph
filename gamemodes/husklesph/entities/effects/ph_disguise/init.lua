function EFFECT:Init(data)
	self.StartTime = CurTime()
	self.NextFlame = CurTime()

	self.pos = data:GetOrigin()
	self.Scale = data:GetScale()
	self.Mag = data:GetMagnitude()

	self.Emitter = ParticleEmitter(self.pos)

	for i = 1, 17 do
		local t = Vector(math.Rand(-self.Scale, self.Scale), math.Rand(-self.Scale, self.Scale), math.Rand(0, self.Mag))
		local particle = self.Emitter:Add("particle/smokesprites_000" .. math.random(1, 9), self.pos + t)
		particle:SetVelocity(t:GetNormal())
		particle:SetDieTime(5.2)
		particle:SetStartAlpha(20)
		particle:SetEndAlpha(0)
		particle:SetStartSize(self.Scale * 2)
		particle:SetEndSize(self.Scale * 2)
		particle:SetRoll(math.random(0, 360))
		local x = math.random(50, 150)
		particle:SetColor(x, x, x)
	end
end

function EFFECT:Think()
	self.Emitter:Finish()
	return false
end

function EFFECT:Render()
end
