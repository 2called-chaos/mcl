# MCL - Minecraft Listener

MCL is a ruby script which acts as a process wrapper for your vanilla minecraft server. It is limited to what the Minecraft
server console outputs and accepts in form of commands. It's original use was to autoupdate snapshot servers but it now offers
a lot more features which are mostly controlled via chat commands. You can compare MCL to an IRC bot or something.

It should be somewhat easy to write custom commands but there are some gotchas to it. If you can't figure it out from
the shipped handlers just ask your question as an issue.



## Features
  * Monitors itself and your minecraft server and restart on crash
  * Reload handlers/commands without restarting
  * Simple ACL support (level based ACL)
  * Snap2date - autoupdate minecraft server
  * Shortcuts, shortcuts, shortcuts (potions effects, cheats, gamerules, ...)
  * Warps - save and warp to coordinates
  * WorldEdit light - selections, stacking and more (using 1.8 commands)
  * Schematic Builder - paste schematics in vanilla (sort of)
  * Butcher - kill entities like a pro
  * Worldbook - switch between and create new worlds (no, it's not multiverse)
  * a lot more commands, shortcuts and awesome stuff...



## Upcoming features
  * Backups - backup and restore your worlds (scheduled or when you need it)
  * Flagbook - Easy access to flags
  * Bannerbook - Easy access to banners
  * generally, add more books. books are good!
  * [**» add something to the list**](https://github.com/2called-chaos/mcl/issues/new)



## Facts
  * MCL starts the minecraft server for you, essentially wrapping it. Therefore, if MCL dies, your minecraft server
    goes along with it. But MCL tries everything to prevent this from happening. It even restarts died servers.
  * MCL does not modify minecraft itself in any way! It's reading and writing from and to the server console only.
  * MCL may download, create, symlink, backup, restore, delete or modify files and folders inside your server folder.



## Requirements
  * Ruby >= 1.9.3 (preferably >2) incl. RubyGems
    * Bundler gem (`gem install bundler`)
  * git (`apt-get install git` / `brew install git`)
  * Unixoid OS (such as Ubuntu/Debian, OS X, maybe others)
  * local minecraft server(s)



## Setup
  **WARNING: MCL isn't released yet and might not work for you**

  0. Do everything as the user which runs the servers except maybe the symlink in step 2.
  1. Download or clone the whole thing to a convenient location:
      <pre>
        cd ~
        git clone https://github.com/2called-chaos/mcl.git</pre>
  2. Optional but recommended: Add the bin directory to your $PATH variable or create a symlink to the executable:
      <pre>
        echo 'export PATH="$HOME/mcl/bin:$PATH"' >> ~/.profile && source ~/.profile
        OR
        ln -s /home/minecraft_server/mcl/bin/mcld /usr/local/bin/mcld</pre>
  3. Install the bundle
      <pre>
        cd ~/mcl && bundle install --without mysql --deployment</pre>
     **NOTE:** If you want to use MySQL (not recommended) replace `mysql` with `sqlite`
  4. Copy and edit the example configuration to fit your needs and server settings.
     Please note that there is currently no user support which means all servers need to run under the same user as MCL does.
      <pre>
        cd ~/mcl
        nano config/default.yml</pre>
  5. Done! Run `mcld start` to start the MCL daemon. Doesn't work? [=> Troubleshooting](https://github.com/2called-chaos/mcl/wiki/Troubleshooting)



## Deactivate handlers
If you want to deactivate buildin handlers (or 3rd party ones) just rename the file to start with two underscores (e.g.: `__warps.rb`).



## Custom handlers
If you want to add a custom handler (there is not much of documentation yet but feel free to ask if you can't figure it out) just place a ruby file inside `vendor/handlers`. As long as it doesn't start with two underscores it get's loaded. You can nest directories as much as you want as MCL traverses this directory recursively.



## Gotchas
  * Players fetched via player manager get cached. The cache get saved and cleared according to the player_cache_save_rate.
    If you fetch players via `Player` model class be sure to call `#clear_cache` on the player manager beforehand.
  * Always make sure to synchronize to the main loop if necessary (it is in a lot of cases) when working with async tasks.
  * Promises are already synchronized to the main loop as they get called by it.
  * Don't block the main loop to long (this includes everything except async code which isn't synchronized to the main loop).



## Contributing
  Contributions are very welcome! Either report errors, bugs and propose features or directly submit code:

  1. Fork it
  2. Create your feature branch (`git checkout -b my-new-feature`)
  3. Commit your changes (`git commit -am 'Added some feature'`)
  4. Push to the branch (`git push origin my-new-feature`)
  5. Create new Pull Request
