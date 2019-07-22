# MCL - Minecraft Listener

MCL is a ruby script which acts as a **wrapper** for your vanilla Minecraft server. It's original use was to autoupdate snapshot servers but it now offers a lot more features which are mostly controlled via chat commands. You can compare MCL to an IRC bot.

It should be somewhat easy to write custom commands but there are some gotchas to it. If you can't figure it out from
the shipped handlers just ask your question in the issues.

MCL is aimed at linux users with a basic knowledge of how servers work but feel free to try :) I haven't tested the Windows installer in a while.

### [» https://mcl.breitzeit.de <small>(read this with TOC / documentation)</small>](https://mcl.breitzeit.de)

---

## Help
If you need help or have problems [open an issue](https://github.com/2called-chaos/mcl/issues/new) or [chat with me](http://discord.gg/2vDfU4C). Please note that I'm not always there so either be patient, stubborn or just create an issue (I won't bite you). Also make sure to _highlight_ me in Discord (`@2called-chaos`).

## Features
  * Monitors itself and your minecraft server and restarts both when they crash
  * Simple **ACL** support (level based ACL)
  * **[Awesome buildin handlers](https://mcl.breitzeit.de/handlers/buildin)**, **[extra handlers](https://mcl.breitzeit.de/handlers/extra)** and you may [create your own](https://mcl.breitzeit.de/handlers/custom) as well!
    Just to name a few (or the coolest):
      * **[Butcher](https://mcl.breitzeit.de/handlers/buildin/butcher)** Kill entities with convenience.
      * **[Lagtrack](https://mcl.breitzeit.de/handlers/buildin/lagtrack)** Keeps track of (and optionally notifies players about) minecraft server lag.
      * **[CBS builder](https://mcl.breitzeit.de/handlers/buildin/cbs_builder)** Write command block stuff (or pixel art) in a text editor and put it into the game by rightclicking a sign (or typing a command)
      * **[Snap2date](https://mcl.breitzeit.de/handlers/buildin/snap2date)** Update to new snapshots automatically or just get notified.
      * **[Warps](https://mcl.breitzeit.de/handlers/buildin/warps)** Save coordinates (per world or global/per player or all), share them or just teleport there.
      * **[WorldEdit light](https://mcl.breitzeit.de/handlers/buildin/world_edit_light)** selections, stacking and more (using 1.8 commands)
      * **[Worlds](https://mcl.breitzeit.de/handlers/buildin/worlds)** Switch between worlds (restarts the server), make or restore backups, have per-world server.properties



## Upcoming features

  * [**» add something to the list**](https://github.com/2called-chaos/mcl/issues/new)



## Requirements
  * Ruby >= 1.9.3 (preferably >2) incl. RubyGems ([chruby](https://gist.github.com/2called-chaos/e06bf6322525d37a5bf7))
    * Bundler gem (`gem install bundler`)
  * git (`apt-get install git` / `brew install git`)
  * Unixoid OS (such as Ubuntu/Debian, OS X, maybe others) or Windows 7/8 (not recommended)
  * local minecraft server(s)
    * **WARNING:** Some feature require the gamerule `logAdminCommands` to be set to true!
    * MCL heavily relies on server commands and implement snapshot features. If things don't work your minecraft server version is probably outdated or I screwed up something.



## Installation
  **NOTE: If you plan on using MCL for <= 1.12 servers you can try using the master branch but we recommend to use the `stable_upto_1.12` tag or `v1.0.0` release**

  **NOTE: MCL is currently in BETA stage!**

  <big>**[» Installation instructions (Debian/Ubuntu/OS X)](https://mcl.breitzeit.de/install_nix)**</big><br>
  <big>**[» Installation instructions (Windows)](https://mcl.breitzeit.de/install_windows)**</big><br>

  **[» FAQ](https://mcl.breitzeit.de/faq)**<br>
  **[» Troubleshooting](https://mcl.breitzeit.de/troubleshooting)**


## Deactivate handlers
If you want to deactivate buildin handlers (or 3rd party ones) just rename the file to start with two underscores (e.g.: `__warps.rb`).
If you want to activate/deactivate extra/legacy handlers we recommend you to symlink them instead of renaming (on linux). This way you
won't get issues when updating via git. E.g. `cd vendor/handlers/_extras; ln -s __horsecars.rb horsecars.rb` and to deactivate just `rm horsecars.rb`

## Use MCL for multiple servers
MCL supports multiple instances. Create a new configuration and start/stop the instance like this:
```
MCLI=config_name mcld start
```

## Console access
MCL is designed to run as a daemon. Since it wraps the process you lose the server console (unless you have the GUI console ofc). We have an experimental console server that you can configure in your instance yml config file. To access the console run something like this:
```
MCLI=config_name mcld console # (also check out `-h`)
```
If you are in, try `?help` and `commands`. I know `help` and explanations are missing but you will figure it out. Or ask :D Oh and everything starting with a `/` will be send as command to your Minecraft server. Inputs starting with a `.*` equal `/say *` (e.g. `.hi, wassup?` => `/say hi, wassup?`)

**NOTE:** While there is a simple authentication the whole thing is not encrypted! It's only recommended to use this locally. You may use SSH port tunnels to access it but since you need MCL, your config and the autoconfig file it's very annoying, rather SSH and run the console ;)

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
- Bridges (e.g. Twitter, IRC)
- Notifications (e.g. server overloaded, server restart, version update, etc.)
- Games (Mr. X)
- Worldsettings (apply server properties / gamerules per world by using a text config)
- Roll the Dice
- disable/choose handlers (instance config)
- disable/choose commands (instance config)
- dynamic groups / permissions
  - ability to make some commands available through playtime


## Why is this useful?
Normal modifications usually break on new releases and/or don't get updates for snapshot versions. Most other wrappers work by intercepting network data packets but this also tends to break sooner or later when things change. MCL on the other hand just parses console output and responds with commands. Unless the log output changes (~~which happened only once in Minecraft history as far as I know~~ 1.13 screwed everything) or commands get removed MCL will continue to work. The drawback is obviously that MCL is much more limited.

In addition, Ruby makes it really easy to communicate and work with external services and that's where I see it's strengths and uses. Things which require really fast ticking checks are overkill for MCLs model.



## Facts
  * MCL encourages you to **always make backups**. MCL is not to blame for any data loss.
  * MCL may use features only available in snapshot versions but most parts should work for you.
  * MCL starts the minecraft server for you, essentially wrapping it. Therefore, if MCL dies, your minecraft server
    goes along with it. But MCL tries everything to prevent this from happening. It even restarts died servers.
  * MCL is limited to what the Minecraft server console outputs and accepts in form of commands.
  * MCL does not take away the Minecraft server console unless you start the server with `nogui`.
  * **MCL does not modify minecraft** itself in any way! It's reading from and writing to the server console only.
  * MCL may download, create, symlink, backup, restore, delete or modify files and folders inside your server folder.
  * When you see "ticks" somewhere it refers to the MCL loop. It has nothing to do with Minecraft ticks.



## Contributing
  Contributions are very welcome! Either report errors, bugs and propose features or directly submit code:

  1. Fork it
  2. Create your feature branch (`git checkout -b my-new-feature`)
  3. Commit your changes (`git commit -am 'Added some feature'`)
  4. Push to the branch (`git push origin my-new-feature`)
  5. Create new Pull Request



## Legal
* © 2014-2019, Sven Pachnit (www.bmonkeys.net)
* MCL is licensed under the MIT license.
* MCL is **not** affiliated with Mojang but if you use MCL you also agree to the [Minecraft EULA](https://account.mojang.com/documents/minecraft_eula).
* "Minecraft" is a trademark of ~~Notch Development AB/Mojang~~ Mojang Synergies AB.
