local killFeedEvents = {}

local KILL_FEED_MESSAGE_TIMEOUT = 10 -- How long a message stays in the kill feed before starting to fade away
local FADE_UPDATE_INTERVAL = 0.1 -- How long to wait before increasing the fade-ness of an expiring kill feed entry
local FADE_TIME = 1.5 -- How long it takes for a kill feed entry to fade away

local NUM_FADE_TICKS = math.floor(FADE_TIME / FADE_UPDATE_INTERVAL)
local FADE_AMOUNT = math.floor(255 / NUM_FADE_TICKS)

function GM:ClearKillFeed()
	killFeedEvents = {}
end

-- This timer modifies the alpha values of each part of a kill feed message to create a "fading out" effect
timer.Create("ph_timer_kill_feed", FADE_UPDATE_INTERVAL, 0, function()
	local event = killFeedEvents[1]
	if event && event.entryTime + KILL_FEED_MESSAGE_TIMEOUT < CurTime() then
		if event.attackerName then
			event.attackerColor.a = event.attackerColor.a - FADE_AMOUNT
		end
		event.victimColor.a = event.victimColor.a - FADE_AMOUNT
		event.messageColor.a = event.messageColor.a - FADE_AMOUNT
		if event.messageColor.a < 0 then
			table.remove(killFeedEvents, 1)
		end
	end
end)

net.Receive("ph_kill_feed_add", function(len)
	local killData = net.ReadTable()
	killData.entryTime = CurTime()

	table.insert(killFeedEvents, killData)
end)

local function drawKillFeedHUD()
	local font = "RobotoHUD-15"
	for index, event in ipairs(killFeedEvents) do
		surface.SetFont(font)
		-- Oldest events should be on the bottom
		local heightOffset = 10 + ((#killFeedEvents - index) * draw.GetFontHeight(font))
		local widthOffset = ScrW() - 10 - surface.GetTextSize(event.victimName) - surface.GetTextSize(" ") - surface.GetTextSize(event.message)
		if event.attackerName then
			widthOffset = widthOffset - surface.GetTextSize(event.attackerName) - surface.GetTextSize(" ")
		end

		-- TODO: After reorganizing how draw.ShadowText is done, replace all of these double-draws with a single ShadowText
		-- Attacker or victim name
		if event.attackerName then
			draw.SimpleText(event.attackerName .. " ", font, widthOffset + 1, heightOffset + 1, Color(0, 0, 0, event.attackerColor.a))
			widthOffset = widthOffset + draw.SimpleText(event.attackerName .. " ", font, widthOffset, heightOffset, event.attackerColor)
		else
			draw.SimpleText(event.victimName .. " ", font, widthOffset + 1, heightOffset + 1, Color(0, 0, 0, event.victimColor.a))
			widthOffset = widthOffset + draw.SimpleText(event.victimName .. " ", font, widthOffset, heightOffset, event.victimColor)
		end

		-- Message
		draw.SimpleText(event.message .. (event.attackerName && " " || ""), font, widthOffset + 1, heightOffset + 1, Color(0, 0, 0, event.messageColor.a))
		widthOffset = widthOffset + draw.SimpleText(event.message .. (event.attackerName && " " || ""), font, widthOffset, heightOffset, event.messageColor)

		-- Attacker name (if present)
		if event.attackerName then
			draw.SimpleText(event.victimName, font, widthOffset + 1, heightOffset + 1, Color(0, 0, 0, event.victimColor.a))
			draw.SimpleText(event.victimName, font, widthOffset, heightOffset, event.victimColor)
		end
	end
end

hook.Add("HUDPaint", "ph_kill_feed_hud_paint", drawKillFeedHUD)
