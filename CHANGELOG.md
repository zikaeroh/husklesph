# Changelog

## Unreleased

## v1.11.2

-   Further improve killfeed messages. (Thanks, Yolo!)

## v1.11.1

-   Fix broken skull icon. (Thanks, Yolo!)
-   Improve killfeed messages and look. (Thanks, Yolo!)

## v1.11.0

-   The end-game menu has been overhauled. (Thanks, Yolo!)
    -   End screen is now a regular window, which can be closed and reopened (with the C key).
    -   Since the menu can be closed, players are no longer stuck looking in the direction they faced when the round ends.
    -   End-screen chat has been removed, and the regular in-game chat is no longer disabled.
-   Fixed pre-round message to not disappear when there weren't enough players. (Thanks, Yolo!)
-   Many, many code cleanups, reformatting, restructuring, and CI checks.

## v1.10.1

-   Add `ph_map_time_limit`, which sets a number of minutes before the "last round".
    For example, if set to 20, then after 20 minutes the game will announce that it's
    the "last round", and on round end will start the mapvote. By default this option is disabled (-1). (Thanks, Yolo!)

## v1.10.0

-   Clean up chat message syste. (Thanks, Yolo!)
-   Add UI element to show map start wait time. (Thanks, Yolo!)
-   Massively improve spawn point creation, allowing maps with too few spawn points to still work. (Thanks, Yolo!)
-   Disable built-in mapvote system when the MapVote addon is installed. (Thanks, Yolo!)

## v1.9.1

-   Fix the URL used to check if the mod is out of date. (Thanks, Yolo!)

## v1.9.0

-   Clean up dead code. (Thanks, Yolo!)
-   Rework prop ban system to no longer delete props from the map, but just disallow them. (Thanks, Yolo!)

## v1.8.8

-   Improve disguising to allow large props to change disguises more easily. (Thanks, foodflare!)

## v1.8.7

-   Fix potential errors on ragdolling due to old code typo. (Thanks, Richy_s\_!)

## v1.8.6

-   Add ULX (out of tree change).

## v1.8.5

-   Fix broken convar ordering.

## v1.8.4

-   Fix bad team colors on round end screen.
-   Allow taunts for all teams.
-   Remove debug prints.

## v1.8.3

-   Compare playermodels case insentively.

## v1.8.2

-   Fix version bump.

## v1.8.1

-   Remove some leftover debugging prints.

## v1.8.0

-   Taunts can be restricted to a specific player model. See the taunt docs for more info.

## v1.7.0

-   The `ph_endround` command forces a the round to end on a tie.
-   Team colors and player colors should be consistent and not change when another mod changes the player model/color.

## v1.6.0

-   Prop deathsounds can be customized per-user by placing a key-value file named `ph_deathsounds.txt` into the `husklesph` directory. For example:

```lua
"PH_Deathsounds"
{
    "default"    "ambient/voices/f_scream1.wav"
    "STEAM_0:1:12345678"
    {
        "1"    "vo/npc/male01/hacks01.wav"
        "2"    "vo/npc/male01/hacks02.wav"
        "3"    "vo/npc/male01/thehacks01.wav"
        "4"    "vo/npc/male01/thehacks02.wav"
    }
    "STEAM_0:1:87654321" "vo/npc/male01/hacks01.wav"
    "STEAM_0:1:13467928"
    {
        "1"    "vo/npc/male01/hacks01.wav"
        "2"    "vo/npc/male01/hacks02.wav"
    }
}
```

## v1.5.1

-   Fix an error when no taunts are possible.

## v1.5.0

-   On death, taunts no longer persist into spectator mode.
-   The taunt menu remembers your mouse position when reopened.
-   The taunt menu phrase is customizable. For example: `ph_taunt_menu_phrase "annoy the hunters"`
-   Taunt loader logging prints the full path to the loaded file, not just the filename itself.
-   Errors during taunt loading are no longer (mistakenly) ignored.
-   Versions are now prefixed with "v" to avoid version checks failing due to floating point coercion.
-   Auto taunts are natively supported!
    -   Enable with `ph_auto_taunt 1`. The default is disabled.
    -   Set `ph_auto_taunt_delay_min` and `ph_auto_taunt_delay_max` to control the frequency of auto taunts in seconds. If a player doesn't taunt (within a randomly selected time between those two values), they will be forced to taunt. The default range is `[60, 120]`.
    -   Set `ph_auto_taunt_props_only 0` to enable auto taunts for hunters. The default is to only auto taunt for props.

## v1.4.0

Original code from MechanicalMind.
