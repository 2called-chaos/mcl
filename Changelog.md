## 2.0.0

### Features

* Added (extra) world pregenerator handler
  (teleport a player in spec mode around the map in a bigger and bigger circle)

* Added (buildin) alias handler
  (allows for per-user or serverwide aliases that execute one ore more (MCL) commands)

* Added (extra) horsecars handler
  (easy way to spawn and manage "tuned" horses)

* Added an experimental console server, see readme for more details

* Added CBS builder (not really new but now documented), see CBS handler docs for more details

### Updates

* Completely reworked the buildin handler "worlds" which now supports per-world server.properties
* Added !weather toggle command to (buildin) weather_and_time handler toggling the doWeatherCycle gamerule
* The !sprop command now supports -f (force) and -r (restart) options
* Snap2date and server bootstrapping now use proper JSON manifest to check for and download server jars and support "latest" and "snapshot" keyword
* bootstrapping now support additional server properties to be set
* Player position detection now uses relative teleports and should be more accurate (and work everywhere)
* Handlers get a new API method `srvrdy` which will be called when the Minecraft server signals that it's ready

* (buildin) handler "enchant" got it's enchantment list updated
* (buildin) handler "butcher" got it's entity lists updated
* (buildin) handler "gamerules" got new commands to accommodate for new gamerules in the game

### Removals

**NOTE:** These handlers are still available in `vendor/handlers/_legacy`

* Removed (buildin) handler "schematic_builder" to rudimentary build .mcschematic files in favor of structure blocks and too much hassle :) (it might come back at some point)
* Removed (extra) handler "bingo" to control minecraft bingos in favor of new world handler and other improvements
* Removed (extra) handler "nbt_inspector" which allowed locating generated strongholds in favor of /locate command
* Removed (extra) handler "village_info" which allowed access to villages NBT info but it only works up to 1.13

### Fixes

* (buildin) handler "lagtrack" now works with 1.13 and higher (log format changes)
* (buildin) handler "gamemode" now works with 1.13 and higher (command changes)
* (buildin) handler "cheats" now works with 1.13 and higher (execute changes)
* (buildin) handler "weather_and_time" now works with 1.13 and higher (commands with trailing spaces)
* (buildin) handler "misc" now works with 1.13 and higher (execute changes)
* (buildin) handler "warps" now works with 1.13 and higher (commands changes)
* (buildin) handler "creative" now works with 1.13 and higher (commands changes)
* (buildin) handler "cbs_builder" now works with 1.13 and higher (commands changes)
* (buildin) handler "world_edit_light" now works with 1.13 and higher (commands changes)
* (buildin) handler "enchant" now works with 1.13 and higher (execute changes)
* (extra) handler "world_saver" now works with 1.13 and higher (log format changes)
* (extra) handler "simple_calc" variable support is now working
* Lots and lots of command changes, there might still be some broken or not ported, feel free ;)


### Documentation

* Added documentation for console server/client

-------------------

## 1.0.0

Legacy (everything up until I decided to make versions/changelogs)
This is latest 1.12 stable. Newer versions might work but lots of new features will not support old command syntax.

-------------------
