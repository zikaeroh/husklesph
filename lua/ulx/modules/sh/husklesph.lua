if engine.ActiveGamemode() ~= "husklesph" then return end

local CATEGORY_NAME = "HusklesPH"

local function commandToUlx(commandName, setupFunc)
    local function func(calling_ply, ...)
        local args = {...}

        for i, v in ipairs(args) do
            if type(v) == "boolean" then
                if v then args[i] = "1" else args[i] = "0" end
            else
                args[i] = tostring(v)
            end
        end

        RunConsoleCommand(commandName, unpack(args))
    end

    local c = ulx.command(CATEGORY_NAME, "ulx " .. commandName, func, "!" .. commandName)
    c:defaultAccess(ULib.ACCESS_ADMIN)

    if setupFunc then setupFunc(c) end

    return c
end

commandToUlx("ph_voice_hearotherteam", function(c)
    c:addParam{ type=ULib.cmds.BoolArg, hint="enabled", ULib.cmds.optional }
    c:help("Enable/disable the ability to hear the voice chat of the other team.")
end)

commandToUlx("ph_voice_heardead", function(c)
    c:addParam{ type=ULib.cmds.BoolArg, hint="enabled", ULib.cmds.optional }
    c:help("Enable/disable the ability to hear the voice chat of the dead.")
end)

commandToUlx("ph_roundlimit", function(c)
    c:addParam{ type=ULib.cmds.NumArg, default=10, min=5, max=100, hint="rounds", ULib.cmds.round, ULib.cmds.optional }
    c:help("Set the round limit for the current map.")
end)

commandToUlx("ph_mapstartwait", function(c)
    c:addParam{ type=ULib.cmds.NumArg, default=30, min=0, max=600, hint="seconds", ULib.cmds.round, ULib.cmds.optional }
    c:help("Set the number of seconds to wait before starting a map.")
end)

commandToUlx("ph_hunter_dmgpenalty", function(c)
    c:addParam{ type=ULib.cmds.NumArg, default=3, min=0, max=100, hint="damage", ULib.cmds.round, ULib.cmds.optional }
    c:help("Set the amount of damage taken by hunters for shooting the wrong prop.")
end)

commandToUlx("ph_hunter_smggrenades", function(c)
    c:addParam{ type=ULib.cmds.NumArg, default=1, min=0, max=5, hint="damage", ULib.cmds.round, ULib.cmds.optional }
    c:help("Set the number of SMG grenates hunters should spawn with.")
end)

commandToUlx("ph_dead_canroam", function(c)
    c:addParam{ type=ULib.cmds.BoolArg, hint="enabled", ULib.cmds.optional }
    c:help("Enable/disable roaming spectator view for dead players.")
end)

commandToUlx("ph_props_onwinstayprops", function(c)
    c:addParam{ type=ULib.cmds.BoolArg, hint="enabled", ULib.cmds.optional }
    c:help("Set whether or not the teams swap when the props win.")
end)

commandToUlx("ph_props_small_size", function(c)
    c:addParam{ type=ULib.cmds.NumArg, default=200, min=0, max=1000, hint="penalty", ULib.cmds.round, ULib.cmds.optional }
    c:help("Set the speed pentaly for small props.")
end)

commandToUlx("ph_props_jumppower", function(c)
    c:addParam{ type=ULib.cmds.NumArg, default=1.2, min=0, max=10, hint="bonus", ULib.cmds.optional }
    c:help("Set the jump power bonus for props.")
end)

commandToUlx("ph_props_camdistance", function(c)
    c:addParam{ type=ULib.cmds.NumArg, default=1, min=1, max=10, hint="distance", ULib.cmds.round, ULib.cmds.optional }
    c:help("Set the camera distance multiplier for disguised props.")
end)

commandToUlx("ph_taunt_menu_phrase", function(c)
    c:addParam{ type=ULib.cmds.StringArg, hint="phrase", default="", ULib.cmds.optional }
    c:help("Set the taunt menu phrase.")
end)


commandToUlx("ph_auto_taunt", function(c)
    c:addParam{ type=ULib.cmds.BoolArg, hint="enabled", ULib.cmds.optional }
    c:help("Enable/disable auto taunt.")
end)

function ulx.husklesphAutoTauntDelay(calling_ply, minimum, maximum)
    if minimum > maximum then
        minimum = maximum
    elseif maximum < minimum then
        maximum = minimum
    end

    RunConsoleCommand("ph_auto_taunt_delay_min", tostring(minimum))
    RunConsoleCommand("ph_auto_taunt_delay_max", tostring(maximum))
end

local autoTauntDelay = ulx.command(CATEGORY_NAME, "ulx ph_auto_taunt_delay", ulx.husklesphAutoTauntDelay, "!ph_auto_taunt_delay")
autoTauntDelay:defaultAccess(ULib.ACCESS_ADMIN)
autoTauntDelay:addParam{ type=ULib.cmds.NumArg, default=60, min=5, max=600, hint="minimum", ULib.cmds.round, ULib.cmds.optional }
autoTauntDelay:addParam{ type=ULib.cmds.NumArg, default=120, min=5, max=600, hint="minimum", ULib.cmds.round, ULib.cmds.optional }
autoTauntDelay:help("Set the auto taunt delay range.")


commandToUlx("ph_endround", function(c)
    c:help("Ends the round on a tie.")
end)

commandToUlx("ph_map_time_limit", function(c)
    c:addParam{ type=ULib.cmds.NumArg, default=-1, min=-1, max=120, hint="minutes", ULib.cmds.optional }
    c:help("Minutes before declaring the next round to be the last round (-1 to disable)")
end)