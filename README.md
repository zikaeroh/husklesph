# Prop Hunters - Huskles Edition

This is a fork of MechanicalMind's Prop Hunters, intended to fix a few bugs and add a few features.
For now, things are backwards compatible with the original gamemode, but I may make breaking changes
in the future.

## Improvements

- On death, taunts no longer persist into spectator mode.
- The taunt menu remembers your mouse position when reopened.
- The taunt menu phrase is customizable. For example: `ph_taunt_menu_phrase "annoy the hunters"`
- Taunt loader logging prints the full path to the loaded file, not just the filename itself.
- Errors during taunt loading are no longer (mistakenly) ignored.
- Versions are now prefixed with "v" to avoid version checks failing due to floating point coercion. (Plus, they're now semver.)

## TODO

- Better handle taunt durations.
    - Allow each individual file to have its own duration, rather than one per taunt.
    - Better handle non-wav file durations. ogg _kinda_ works, but sometimes `SoundDuration` gives the wrong duration and allows taunts to overlap.
- General code cleanup.
    - There's a lot of oddity in this codebase, along with loads of dead code copied from other gamemodes.
- Improve disguising for large props.
    - The reach of a large prop isn't always far enough to be able to change into something else.
