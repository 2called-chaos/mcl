# MCL - Minecraft Listener

MCL is a ruby script which acts as a **wrapper** for your vanilla Minecraft server. It's original use was to autoupdate snapshot servers but it now offers a lot more features which are mostly controlled via chat commands. You can compare MCL to an IRC bot.

It should be somewhat easy to write custom commands but there are some gotchas to it. If you can't figure it out from
the shipped handlers just ask your question in the issues.

### [» https://mcl.breitzeit.de <small>(read this with TOC / documentation)</small>](https://mcl.breitzeit.de)

---

## Help
If you need help or have problems [open an issue](https://github.com/2called-chaos/mcl/issues/new) or [chat with me](http://webchat.esper.net/?channels=mcl). Please note that I'm not always there so either be patient, stubborn or just create an issue (I won't bite you). Also make sure to _highlight_ me in IRC by including my full nickname _soahccc_ in your message.


## Features
  * Monitors itself and your minecraft server and restarts both when they crash
  * Simple **ACL** support (level based ACL)
  * **[Awesome buildin handlers](https://mcl.breitzeit.de/handlers/buildin)**, **[extra handlers](https://mcl.breitzeit.de/handlers/extra)** and you may [create your own](https://mcl.breitzeit.de/handlers/custom) as well!
    Just to name a few (or the coolest):
      * **[Butcher](https://mcl.breitzeit.de/handlers/buildin/butcher)** Kill entities with convenience.
      * **[Lagtrack](https://mcl.breitzeit.de/handlers/buildin/lagtrack)** Keeps track of (and optionally notifies players about) minecraft server lag.
      * **[Schematic Builder](https://mcl.breitzeit.de/handlers/buildin/schematic_builder)** Sounds crazy? It is!
      * **[Snap2date](https://mcl.breitzeit.de/handlers/buildin/snap2date)** Update to new snapshots automatically or just get notified.
      * **[Warps](https://mcl.breitzeit.de/handlers/buildin/warps)** Save coordinates (per world or global/per player or all), share them or just teleport there.
      * **[WorldEdit light](https://mcl.breitzeit.de/handlers/buildin/world_edit_light)** selections, stacking and more (using 1.8 commands)
      * **[Worlds](https://mcl.breitzeit.de/handlers/buildin/worlds)** Worldbook (switch between, create new, backup worlds)



## Upcoming features
  * **Backups** - backup and restore your worlds (scheduled or when you need it)
  * **Flagbook** - Easy access to flags
  * **Bannerbook** - Easy access to banners
  * generally, add **more** books. books are good!
  * [**» add something to the list**](https://github.com/2called-chaos/mcl/issues/new)



## Requirements
  * Ruby >= 1.9.3 (preferably >2) incl. RubyGems ([chruby](https://gist.github.com/2called-chaos/e06bf6322525d37a5bf7))
    * Bundler gem (`gem install bundler`)
  * git (`apt-get install git` / `brew install git`)
  * Unixoid OS (such as Ubuntu/Debian, OS X, maybe others) or Windows 7/8 (not recommended)
  * local minecraft server(s)
    * **WARNING:** Some feature require the gamerule `logAdminCommands` to be set to true!
    * MCL heavily relies on server commands and implement snapshot features. If things don't work your minecraft server version is probably outdated.



## Installation
  **NOTE: MCL is currently in BETA stage!**

  <big>**[» Installation instructions (Debian/Ubuntu/OS X)](https://mcl.breitzeit.de/install_nix)**</big><br>
  <big>**[» Installation instructions (Windows)](https://mcl.breitzeit.de/install_windows)**</big><br>

  **[» FAQ](https://mcl.breitzeit.de/faq)**<br>
  **[» Troubleshooting](https://mcl.breitzeit.de/troubleshooting)**


## Deactivate handlers
If you want to deactivate buildin/extra handlers (or 3rd party ones) just rename the file to start with two underscores (e.g.: `__warps.rb`).


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
- Roll the Dice



## Why is this useful?
Normal modifications usually break on new releases and/or don't get updates for snapshot versions. Most other wrappers work by intercepting network data packets but this also tends to break sooner or later when things change. MCL on the other hand just parses console output and responds with commands. Unless the log output changes (which happened only once in Minecraft history as far as I know) or commands get removed MCL will continue to work. The drawback is obviously that MCL is much more limited.

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
* © 2014, Sven Pachnit (www.bmonkeys.net)
* MCL is licensed under the MIT license.
* MCL is **not** affiliated with Mojang but if you use MCL you also agree to the [Minecraft EULA](https://account.mojang.com/documents/minecraft_eula).
* "Minecraft" is a trademark of Notch Development AB/Mojang.
