local killFeedEvents = {}

local KILL_FEED_MESSAGE_TIMEOUT = 10 -- How long a message stays in the kill feed before starting to fade away.
local VISUALS_UPDATE_INTERVAL = 0.05 -- Tick speed of the visual update timer. Smaller number = smoother visuals.
local FADE_TIME = 1.5 -- How long it takes for an expiring kill feed message to fade away.

local NUM_FADE_TICKS = math.floor(FADE_TIME / VISUALS_UPDATE_INTERVAL)
local FADE_AMOUNT = math.floor(255 / NUM_FADE_TICKS)

local FONT = "RobotoHUD-15" -- Font used for kill feed messages.

function GM:ClearKillFeed()
	killFeedEvents = {}
end

-- This timer handles the visual updates for kill feed messages.
-- New messages are given a "slide in" effect wherein they slide in from off-screen.
-- Expiring messages are given a fade out effect.
timer.Create("ph_timer_kill_feed_visuals", VISUALS_UPDATE_INTERVAL, 0, function()
	for i, event in ipairs(killFeedEvents) do
		local finalPos = ScrW() - 10 - event.eventWidth
		-- Handle slide in effect.
		if event.new then
			-- The distance to slide in a single "frame" is going to be proportional to how much distance is
			-- left to the final position. This will be scaled up by 50% to make things go faster.
			local subtractAmt = math.floor((event.x - finalPos) * 0.5)
			-- Always move by at least one pixel.
			if subtractAmt < 1 then
				subtractAmt = 1
			end

			event.x = event.x - subtractAmt
			if event.x < finalPos then
				event.x = finalPos
				event.new = false
			end
		-- Handle the fade out effect.
		elseif event.entryTime + KILL_FEED_MESSAGE_TIMEOUT < CurTime() then
			if event.attackerName then
				event.attackerColor.a = event.attackerColor.a - FADE_AMOUNT
			end
			event.victimColor.a = event.victimColor.a - FADE_AMOUNT
			event.messageColor.a = event.messageColor.a - FADE_AMOUNT
			-- Remove message from the kill feed once it is completely transparent.
			if event.messageColor.a < 0 then
				table.remove(killFeedEvents, i)
			end
		end
	end
end)

net.Receive("ph_kill_feed_add", function(len)
	local event = net.ReadTable()
	event.entryTime = CurTime()
	event.new = true -- New events are events that are in the process of "sliding in" to view.

	-- Starting x position. Individual draw statements will be relative to this value.
	event.x = ScrW() -- This will be offscreen.

	-- Calculate the final width of the entire kill feed event.
	surface.SetFont(FONT)
	event.eventWidth = surface.GetTextSize(event.victimName) + surface.GetTextSize(" ") + surface.GetTextSize(event.message)
	if event.attackerName then
		event.eventWidth = event.eventWidth + surface.GetTextSize(event.attackerName) + surface.GetTextSize(" ")
	end

	-- New events will start at the top.
	event.y = 10

	-- Shift existing events downward.
	for _, kfEvent in ipairs(killFeedEvents) do
		kfEvent.y = kfEvent.y + draw.GetFontHeight(FONT)
	end

	table.insert(killFeedEvents, event)
end)

-- The shadow transparency will be the same as the provided color transparency.
-- Returns the width and height of the NON SHADOW text.
local function drawShadowText(text, font, x, y, color)
	draw.SimpleText(text, font, x + 1, y + 1, Color(0, 0, 0, color.a))
	return draw.SimpleText(text, font, x, y, color)
end

local function drawKillFeedHUD()
	for _, event in ipairs(killFeedEvents) do
		local widthOffset = event.x

		-- New events need to have clipping disabled so they can be drawn while partially off-screen.
		local oldClippingValue
		if event.new then
			oldClippingValue = DisableClipping(true)
		end

		-- If Murder: [Attacker] [Message] [Victim]
		-- If Suicide: [Victim] [Message]

		if event.attackerName then
			widthOffset = widthOffset + drawShadowText(event.attackerName .. " ", FONT, widthOffset, event.y, event.attackerColor)
		else
			widthOffset = widthOffset + drawShadowText(event.victimName .. " ", FONT, widthOffset, event.y, event.victimColor)
		end

		widthOffset = widthOffset + drawShadowText(event.message .. (event.attackerName && " " || ""), FONT, widthOffset, event.y, event.messageColor)

		if event.attackerName then
			drawShadowText(event.victimName, FONT, widthOffset, event.y, event.victimColor)
		end

		if event.new then
			DisableClipping(oldClippingValue)
		end
	end
end

hook.Add("HUDPaint", "ph_kill_feed_hud_paint", drawKillFeedHUD)
