# MCL - Minecraft Listener

MCL is a ruby script which acts as a **wrapper** for your vanilla Minecraft server. It's original use was to autoupdate snapshot servers but it now offers a lot more features which are mostly controlled via chat commands. You can compare MCL to an IRC bot.

It should be somewhat easy to write custom commands but there are some gotchas to it. If you can't figure it out from
the shipped handlers just ask your question in the issues.

## Help
If you need help or have problems [open an issue](https://github.com/2called-chaos/mcl/issues/new) or [chat with me](http://webchat.esper.net/?channels=mcl).


## Features
  * Monitors itself and your minecraft server and restart on crash
  * Reload handlers/commands without restarting
  * Simple **ACL** support (level based ACL)
  * Snap2date - **autoupdate minecraft server**
  * **Shortcuts**, shortcuts, shortcuts (potions effects, cheats, gamerules, ...)
  * **Warps** - save and warp to coordinates
  * **WorldEdit light** - selections, stacking and more (using 1.8 commands)
  * **Schematic Builder** - paste schematics in vanilla (sort of)
  * **Butcher** - kill entities like a pro
  * **Worldbook** - switch between, backup and create new worlds (no, it's not multiverse)
  * a lot more commands, shortcuts and awesome stuff...



## Upcoming features
  * **Backups** - backup and restore your worlds (scheduled or when you need it)
  * **Flagbook** - Easy access to flags
  * **Bannerbook** - Easy access to banners
  * generally, add **more** books. books are good!
  * [**» add something to the list**](https://github.com/2called-chaos/mcl/issues/new)



## Facts
  * MCL encourages you to **always make backups**. MCL is not to blame for any data loss.
  * MCL may use features only available in snapshot versions but most parts should work for you.
  * MCL starts the minecraft server for you, essentially wrapping it. Therefore, if MCL dies, your minecraft server
    goes along with it. But MCL tries everything to prevent this from happening. It even restarts died servers.
  * MCL is limited to what the Minecraft server console outputs and accepts in form of commands.
  * MCL does not take away the Minecraft server console unless you start the server with `nogui`.
  * **MCL does not modify minecraft** itself in any way! It's reading from and writing to the server console only.
  * MCL may download, create, symlink, backup, restore, delete or modify files and folders inside your server folder.
  * The buildin _!eval_ plugin is disabled by default because it's evil!
  * When you see "ticks" somewhere it refers to the MCL loop. It has nothing to do with Minecraft ticks.


## Requirements
  * Ruby >= 1.9.3 (preferably >2) incl. RubyGems ([chruby](https://gist.github.com/2called-chaos/e06bf6322525d37a5bf7))
    * Bundler gem (`gem install bundler`)
  * git (`apt-get install git` / `brew install git`)
  * Unixoid OS (such as Ubuntu/Debian, OS X, maybe others)
    * Windows support is in the work
  * local minecraft server(s)
    * **WARNING:** Some feature require the gamerule `logAdminCommands` to be set to true!


## Installation
  **WARNING: MCL isn't released yet and might not work for you**

  <big>**[» Installation instructions (Debian/Ubuntu/OS X)](https://github.com/2called-chaos/mcl/blob/master/doc/installation_nix.md)**</big><br>
  **» Installation instructions (Windows)** _not yet available_

  **[» FAQ](https://github.com/2called-chaos/mcl/wiki/FAQ)**<br>
  **[» Troubleshooting](https://github.com/2called-chaos/mcl/wiki/Troubleshooting)**


## Deactivate handlers
If you want to deactivate buildin handlers (or 3rd party ones) just rename the file to start with two underscores (e.g.: `__warps.rb`).


## Core handlers
There are some handlers which are considered core functionality and therefore are "hidden" inside the library folder. You should not deactivate these.
Beside some regular parsers the core provides these commands with the permission level (ACL) accordingly:
  * via [_lib/mcl/handlers/acl.rb_](https://github.com/2called-chaos/mcl/blob/master/lib/mcl/handlers/acl.rb)
    * **!acl** (admin)
    * **!op** (admin)
    * **!deop** (admin)
    * **!uadmin** (guest _but may only work when you are listed in the config_)
  * via [_lib/mcl/handlers/core.rb_](https://github.com/2called-chaos/mcl/blob/master/lib/mcl/handlers/core.rb)
    * **!danger** (admin)
    * **!help** (guest)
    * **!mclreboot** (admin)
    * **!mclreload** (admin)
    * **!mclshell** (root)
    * **!mclupdate** (root)
    * **!raw** (admin)
    * **!stop** (admin)
    * **!stopmc** (root)
    * **!sprop** (root)
    * **!version** (member)


## Buildin handlers
MCL ships with a few buildin handlers which you may deactivate if you want. They use a somewhat reasonable ACL setting
(permission level) but you may alter these as well. At the moment there are these buildin handlers:

  * **[Butcher](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/butcher.rb)** Kill entities with convenience.
  * **[Cheats](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/cheats.rb)** Collection of cheaty things (although the rest isn't really better)
  * **[Creative](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/creative.rb)** Shortcuts for creative people
  * **[Eval](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/__eval.rb)** Eval remote ruby code from pastebin.com **disabled by default**
  * **[Gamemode](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/gamemode.rb)** Shortcuts for gamemodes.
  * **[Gamerule](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/gamerule.rb)** Shortcuts for gamerules.
  * **[Potion Effects](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/potion_effects.rb)** Shortcuts for (mostly overpowered) potion effects.
  * **[Schematic Builder](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/schematic_builder.rb)** Sounds crazy? It is!
  * **[Snap2date](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/snap2date.rb)** Update to new snapshots automatically or just get notified.
  * **[Teleport](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/teleport.rb)** Handy !tp command and teleport book.
  * **[Warps](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/warps.rb)** Save coordinates (per world or global/per player or all), share them or just teleport there.
  * **[Weather and Time](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/weather_and_time.rb)** Shortcuts for weather and time commands/gamerules.
  * **[Whois](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/whois.rb)** Gives you a book with information about a player.
  * **[WorldEdit light](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/world_edit_light.rb)** selections, stacking and more (using 1.8 commands)
  * **[Worlds](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/worlds.rb)** Worldbook (switch between, create new, backup worlds)
  * **[Misc](https://github.com/2called-chaos/mcl/blob/master/vendor/handlers/_buildin/misc.rb)** Miscellaneous commands


## Custom handlers
If you want to add a custom handler (there is not much of documentation yet but feel free to ask if you can't figure it out) just place a ruby file inside `vendor/handlers`. As long as it doesn't start with two underscores it get's loaded. You can nest directories as much as you want as MCL traverses this directory recursively.


### Gotchas
  * Players fetched via player manager get cached. The cache get saved and cleared according to the player_cache_save_rate.
    If you fetch players via `Player` model class be sure to call `#clear_cache` on the player manager beforehand.
  * Always make sure to synchronize to the main loop if necessary (it is in a lot of cases) when working with async tasks.
  * Promises are already synchronized to the main loop as they get called by it.
  * Don't block the main loop to long (this includes everything except async code which isn't synchronized to the main loop).


## Use MCL for multiple servers
MCL supports multiple instances. Create a new configuration and start/stop the instance like this:
```
MCLI=config_name mcld start
```

## ACL - what?
ACL stands for Access Control List and it's not really that but think about it as permissions. Each player has a permission
level which is a number starting from 0. Each command also has a permission level and if the player has equal or more points
he can execute the command.

Because numbers are confusing there is a mapping for several "groups" which resolve to a permission level like this:

```
root    => 13333337
admin   => 1333337
mod     => 133337
builder => 13337
member  => 1337
guest   => 0
```

Note: `!help` only shows you commands you have the permission for.

## Ideas
- Ability to make some commands available through playtime
- Bridges (e.g. Twitter, IRC)
- Notifications (e.g. server overloaded, server restart, version update, etc.)
- Games (Mr. X)
- Worldsettings (apply server properties / gamerules per world by using a text config)

## Why is this useful?
Normal modifications usually break on new releases and/or don't get updates for snapshot versions. Most other wrappers work by intercepting network data packets but this also tends to break sooner or later when things change. MCL on the other hand just parses console output and responds with commands. Unless the log output changes (which happened only once in Minecraft history as far as I know) or commands get removed MCL will continue to work. The drawback is obviously that MCL is much more limited.

In addition, Ruby makes it really easy to communicate and work with external services and that's where I see it's strengths and uses. Things which require really fast ticking checks are overkill for MCLs model.

## Legal
* © 2014, Sven Pachnit (www.bmonkeys.net)
* MCL is licensed under the MIT license.
* MCL is **not** affiliated with Mojang.
* If you use MCL you also agree to the [Minecraft EULA](https://account.mojang.com/documents/minecraft_eula).
* "Minecraft" is a trademark of Notch Development AB/Mojang. All rights belong to their respective owners.

## Contributing
  Contributions are very welcome! Either report errors, bugs and propose features or directly submit code:

  1. Fork it
  2. Create your feature branch (`git checkout -b my-new-feature`)
  3. Commit your changes (`git commit -am 'Added some feature'`)
  4. Push to the branch (`git push origin my-new-feature`)
  5. Create new Pull Request
