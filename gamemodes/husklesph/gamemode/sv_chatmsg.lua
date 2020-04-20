-- The file provides the functionality for sending chat messages to players from
-- the server. This is used instead of PrintMessage because we want to have
-- colored messages (PrintMessage can't do this).

util.AddNetworkString("ph_chatmsg")
local PlayerMeta = FindMetaTable("Player")

-- Sends a message to an individual player.
function PlayerMeta:PlayerChatMsg(...)
	net.Start("ph_chatmsg")
	net.WriteTable({...})
	net.Send(self)
end

-- Sends a message to every player.
function GlobalChatMsg(...)
	net.Start("ph_chatmsg")
	net.WriteTable({...})
	net.Broadcast()
end
