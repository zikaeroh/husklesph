-- This file provides the functionality for printing chat messages to the client
-- that are sent by the server. This is used instead of something like MsgC or
-- PrintMessage because we want the messages to be colored (something PrintMessage
-- can't do) and we want to be able to send messages from the server (MsgC can't do
-- this).

net.Receive("ph_chatmsg", function(len)
	local tbl = net.ReadTable()
	chat.AddText(unpack(tbl))
end)
