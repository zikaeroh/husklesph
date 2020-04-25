local helpText = [[
== CONTROLS ==
LEFT CLICK - Disguises as the prop you are looking at
C - Locks your prop's rotation when disguised
F3 - Taunt menu


== OBJECTIVES ==
The aim of the hunters is to find and kill all the props.
Don't shoot too many actual props, as guessing incorrectly costs health!

The aim of the props is to hide from the hunters and not get killed.


== COMMANDS ==
"ph_taunt_random" plays a random taunt.
"ph_taunt <filename>" plays a taunt given a filename.
]]

local menu

local function createHelpMenu()
	menu = vgui.Create("DFrame")
	GAMEMODE.HelpMenu = menu
	menu:SetSize(ScrW() * 0.4, ScrH() * 0.6)
	menu:Center()
	menu:MakePopup()
	menu:SetKeyboardInputEnabled(false)
	menu:SetDeleteOnClose(false)
	menu:ShowCloseButton(true)
	menu:SetTitle("")
	menu:SetVisible(false)

	function menu:Paint(w, h)
		surface.SetDrawColor(40, 40, 40, 230)
		surface.DrawRect(0, 0, w, h)
		surface.SetFont("RobotoHUD-25")
		draw.ShadowText("Help", "RobotoHUD-25", 8, 2, Color(132, 199, 29), 0)
	end

	local text = vgui.Create("DLabel", menu)
	text:SetText(helpText)
	text:SetWrap(true)
	text:SetFont("RobotoHUD-10")
	text:Dock(FILL)

	function text:Paint(w, h) end
end

local function toggleHelpMenu()
	if !IsValid(menu) then
		createHelpMenu()
	end

	menu:SetVisible(!menu:IsVisible())
end

net.Receive("ph_openhelpmenu", toggleHelpMenu)
