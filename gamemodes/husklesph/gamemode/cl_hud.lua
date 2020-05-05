local function createRoboto(s)
	surface.CreateFont("RobotoHUD-" .. s , {
		font = "Roboto-Bold",
		size = math.Round(ScrW() / 1000 * s),
		weight = 700,
		antialias = true,
		italic = false
	})

	surface.CreateFont("RobotoHUD-L" .. s , {
		font = "Roboto",
		size = math.Round(ScrW() / 1000 * s),
		weight = 500,
		antialias = true,
		italic = false
	})
end

for i = 5, 50, 5 do
	createRoboto(i)
end
createRoboto(8)
createRoboto(12)

function draw.ShadowText(n, f, x, y, c, px, py, shadowColor)
	draw.SimpleText(n, f, x + 1, y + 1, shadowColor || color_black, px, py)
	draw.SimpleText(n, f, x, y, c, px, py)
end

function GM:HUDPaint()
	self:DrawGameHUD()
	self:DrawRoundTimer()
end

local helpKeysProps = {
	{"attack", "Disguise as prop"},
	{"menu_context", "Lock prop rotation"},
	{"gm_showspare1", "Taunt"}
}

local function keyName(str)
	str = input.LookupBinding(str)
	return str:upper()
end

function GM:DrawGameHUD()
	local ply = LocalPlayer()
	if self:IsCSpectating() && IsValid(self:GetCSpectatee()) && self:GetCSpectatee():IsPlayer() then
		ply = self:GetCSpectatee()
	end

	self:DrawHealth(ply)

	if ply != LocalPlayer() then
		local col = team.GetColor(ply:Team())
		draw.ShadowText(ply:Nick(), "RobotoHUD-30", ScrW() / 2, ScrH() - 4, col, 1, 4)
	end

	local tr = ply:GetEyeTraceNoCursor()
	local shouldDraw = hook.Run("HUDShouldDraw", "PropHuntersPlayerNames")
	if shouldDraw != false then
		-- draw names
		if IsValid(tr.Entity) && tr.Entity:IsPlayer() && tr.HitPos:Distance(tr.StartPos) < 500 then
			-- hunters can only see their teams names
			if !ply:IsHunter() || ply:Team() == tr.Entity:Team() then
				self.LastLooked = tr.Entity
				self.LookedFade = CurTime()
			end
		end

		if IsValid(self.LastLooked) && self.LookedFade + 2 > CurTime() then
			local name = self.LastLooked:Nick() || "error"
			local col = table.Copy(team.GetColor(self.LastLooked:Team()))
			col.a = (1 - (CurTime() - self.LookedFade) / 2) * 255
			draw.ShadowText(name, "RobotoHUD-20", ScrW() / 2, ScrH() / 2 + 80, col, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, Color(0, 0, 0, col.a))
		end
	end

	local help
	if LocalPlayer():Alive() then
		if LocalPlayer():IsProp() then
			if self:GetGameState() == ROUND_HIDE || (self:GetGameState() == ROUND_SEEK && !LocalPlayer():IsDisguised()) then
				help = helpKeysProps
			end
		end
	end

	if help then
		local fh = draw.GetFontHeight("RobotoHUD-L15")
		local h = #help * fh
		local x = 20
		local y = ScrH() / 2 - h / 2
		local i = 0
		local tw = 0
		for k, t in pairs(help) do
			surface.SetFont("RobotoHUD-15")
			local name = keyName(t[1])
			local w = surface.GetTextSize(name)
			tw = math.max(tw, w)
		end

		for k, t in pairs(help) do
			surface.SetFont("RobotoHUD-15")
			local name = keyName(t[1])
			draw.ShadowText(name, "RobotoHUD-15", x + tw / 2, y + i * fh, color_white, 1, 0)
			draw.ShadowText(t[2], "RobotoHUD-L15", x + tw + 10, y + i * fh, color_white, 0, 0)
			i = i + 1
		end
	end
end

local polyTex = surface.GetTextureID("VGUI/white.vmt")

local function drawPoly(x, y, w, h, percent)
	local points = 40
	if percent > 0.5 then
		local vertexes = {}
		local hpoints = points / 2
		local base = math.pi * 1.5
		local mul = 1 / hpoints * math.pi
		for i = (1 - percent) * 2 * hpoints, hpoints do
			table.insert(vertexes, {x = x + w / 2 + math.cos(i * mul + base) * w / 2, y = y + h / 2 + math.sin(i * mul + base) * h / 2})
		end

		table.insert(vertexes, {x = x + w / 2, y = y + h})
		table.insert(vertexes, {x = x + w / 2, y = y + h / 2})

		surface.SetTexture(polyTex)
		surface.DrawPoly(vertexes)
	end

	local vertexes = {}
	local hpoints = points / 2
	local base = math.pi * 0.5
	local mul = 1 / hpoints * math.pi
	local p = 0
	if percent < 0.5 then
		p = (1 - percent * 2)
	end

	for i = p * hpoints, hpoints do
		table.insert(vertexes, {x = x + w / 2 + math.cos(i * mul + base) * w / 2, y = y + h / 2 + math.sin(i * mul + base) * h / 2})
	end
	table.insert(vertexes, {x = x + w / 2, y = y})
	table.insert(vertexes, {x = x + w / 2, y = y + h / 2})

	surface.SetTexture(polyTex)
	surface.DrawPoly(vertexes)
end

function GM:DrawHealth(ply)
	local x = 20
	local w, h = math.ceil(ScrW() * 0.09), 80
	h = w
	local y = ScrH() - 20 - h
	local ps = 0.05

	surface.SetDrawColor(50, 50, 50, 180)
	drawPoly(x, y, w, h, 1)

	render.ClearStencil()
	render.SetStencilEnable(true)
	render.SetStencilFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilZFailOperation(STENCILOPERATION_KEEP)
	render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_ALWAYS)
	render.SetStencilWriteMask(1)
	render.SetStencilTestMask(1)
	render.SetStencilReferenceValue(1)
	render.SetBlend(0)
	render.OverrideDepthEnable(true, false)

	surface.SetDrawColor(26, 120, 245, 1)
	drawPoly(x + w * ps, y + h * ps, w * (1 - 2 * ps), h * (1 - 2 * ps), 1)

	render.SetStencilEnable(true)
	render.SetStencilCompareFunction(STENCILCOMPARISONFUNCTION_EQUAL)
	render.SetStencilPassOperation(STENCILOPERATION_REPLACE)
	render.SetStencilReferenceValue(1)

	local health = ply:Health()
	local maxhealth = math.max(health, ply:GetHMaxHealth())
	local nh = math.Round((h - ps * 2) * math.Clamp(health / maxhealth, 0, 1))
	local tcol = table.Copy(team.GetColor(ply:Team()))
	tcol.a = 150
	surface.SetDrawColor(tcol)
	surface.DrawRect(x, y + h - ps - nh, w, nh)

	draw.ShadowText(math.Round(health) .. "", "RobotoHUD-25", x + w / 2, y + h / 2, color_white, 1, 1)

	render.SetStencilEnable(false)
	render.SetStencilWriteMask(0)
	render.SetStencilReferenceValue(0)
	render.SetStencilTestMask(0)
	render.SetStencilEnable(false)
	render.OverrideDepthEnable(false)
	render.SetBlend(1)

	cam.IgnoreZ(false)

	if ply:IsDisguised() && ply:DisguiseRotationLocked() then
		local fg = draw.GetFontHeight("RobotoHUD-15")
		draw.ShadowText("ROTATION", "RobotoHUD-15", x + w + 20, y + h / 2 - fg / 2, color_white, 0, 1)
		draw.ShadowText("LOCK", "RobotoHUD-15", x + w + 20, y + h / 2 + fg / 2, color_white, 0, 1)
	end
end

function GM:HUDShouldDraw(name)
	if name == "CHudHealth" then return false end
	if name == "CHudVoiceStatus" then return false end
	if name == "CHudVoiceSelfStatus" then return false end

	return true
end

function GM:DrawRoundTimer()
	if self:GetGameState() == ROUND_WAIT then
		local time = math.ceil(self.StartWaitTime:GetFloat() - self:GetStateRunningTime())
		if time > 0 then
			draw.ShadowText("Waiting for players to join", "RobotoHUD-25", ScrW() / 2, ScrH() / 10 - draw.GetFontHeight("RobotoHUD-40") / 4, color_white, 1, 4)
			draw.ShadowText("Game starts in " .. tostring(time) .. " second" .. (time > 1 && "s" || ""), "RobotoHUD-15", ScrW() / 2, ScrH() / 10, color_white, 1, 1)
		else
			draw.ShadowText("Not enough players to start game", "RobotoHUD-25", ScrW() / 2, ScrH() / 10 - draw.GetFontHeight("RobotoHUD-40") / 4, color_white, 1, 4)
			draw.ShadowText("Waiting for more players to join", "RobotoHUD-15", ScrW() / 2, ScrH() / 10, color_white, 1, 1)
		end
	elseif self:GetGameState() == ROUND_HIDE then
		local time = math.ceil(30 - self:GetStateRunningTime())
		if time > 0 then
			draw.ShadowText("Hunters will be released in", "RobotoHUD-15", ScrW() / 2, ScrH() / 3 - draw.GetFontHeight("RobotoHUD-40") / 2, color_white, 1, 4)
			draw.ShadowText(time, "RobotoHUD-40", ScrW() / 2, ScrH() / 3, color_white, 1, 1)
		end
	elseif self:GetGameState() == ROUND_SEEK then
		if self:GetStateRunningTime() < 2 then
			draw.ShadowText("GO!", "RobotoHUD-50", ScrW() / 2, ScrH() / 3, color_white, 1, 1)
		end

		local settings = self:GetRoundSettings()
		local roundTime = settings.RoundTime || 5 * 60
		local time = math.max(0, roundTime - self:GetStateRunningTime())
		local m = math.floor(time / 60)
		local s = math.floor(time % 60)
		m = tostring(m)
		s = s < 10 && "0" .. s || tostring(s)
		local fh = draw.GetFontHeight("RobotoHUD-L15") * 1
		draw.ShadowText("Props win in", "RobotoHUD-L15", ScrW() / 2, 20, color_white, 1, 3)
		draw.ShadowText(m .. ":" .. s, "RobotoHUD-20", ScrW() / 2, fh + 20, color_white, 1, 3)
	end
end

function GM:PreDrawHUD()
	local client = LocalPlayer()
	if self:GetGameState() == ROUND_HIDE then
		if client:IsHunter() then
			surface.SetDrawColor(25, 25, 25, 255)
			surface.DrawRect(-10, -10, ScrW() + 20, ScrH() + 20)
		end
	end
end
