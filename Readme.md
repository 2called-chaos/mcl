# Principle

MCL parses the log file on the fly and converts it into events. Handlers can then pickup these events and react upon them.
MCL ships with (a growing amount) of handlers or plugins but it's really easy to create you own ones. Just look at what the core
helps you with.


LogFile -> Parser -> Event -> Handler -> Reaction

# Core functionality

  - Parser to convert Minecraft server log data into events
    We do all the parsing, you just listen to the events you want
  - Persistent ActiveRecord storage
    AR with all it's features. Models, validations and you can choose between sqlite, mysql and postgres!
  - Player manager (keeps track of currently online players. Persistently tracks join/leaves)
    Keeps track of currently online players and provides simple access to player specific persistent and
    non-persistent storage. It also tracks connect and disconnect events to measure some statistics.
  - Time based scheduler
    Need a timer? Just schedule a task for any time and with ActiveSupport we get this: Time.now + 5.minutes + 1.hour
    Note that the scheduler only checks once per tick so it's not firing on the exact second.
  - Server IPC
    Don't care about IPC, we provide screen and tmux support.



# Shipped handlers

These handlers can easily be deactivated by just removing the folder. All of these could have been done by somebody else without altering
the core. Plugins that is.

  - aliases
    Define global or personal aliases for commonly used commands

  - macros
    Define global or personal macros (e.g. !foo executes /spawn Creeper)
    You can chain and roughly time commands.

  - gamemode
    Just a bunch of shortcuts for the gamemode command

  - inventory_slots
    Useful for creative servers. Just save and restore your inventory with as many slots as you like.
    !inv save redstone                # save current inventory as redstone
    !inv sac redstone                 # "save and clear" current inventory as redstone
    !inv delete redstone              # delete saved inventory
    !inv restore tower_build          # restore saved inventory by name
    !inv swap redstone tower_build    # swap inventory (save current as redstone and restore tower_build)

  - mc (minecraft control)
    A whole bunch of features to control your server.

    !mc stop                                    # stop server
    !mc restart                                 # restart minecraft server
    !mc backup <slot>                           # backup current map
    !mc restore <slot>                          # restore map
    !mc update <url>                            # download jar, stop server, symlink, start server
    !mc map "ThisAdventure"                     # stop server, swap map, start server
    !mc instance "ThisAdventure" "ouradventure" # stop server, clone map, start server
    !mc kickall                                 # kick all players
    !op !deop


  - mclag
    Tracks "can't keep up" and provide some statistics for operators (like "when did we have a lot of lag spikes")

  - potion effects
    A bunch of shortcuts for potion effects

  - spawns
    Save positions and warp back to them (works similar to the inventory slot plugin)

  - time
    Time related shortcuts (for /time and /gamerule)

  - weather
    Just some shortcuts

  - world_edit_light
    One of the most interesting parts :)
    The combination of volatile storage and some command magicery we can emulate some basic features of the famous worldedit.

    !!pos1   # selection start
    !!pos2   # selection end
    !!insert # insert selection here
    !!set    # set selection to block (fill)

    Expect more features on this side (like generators (spheres, circles, etc.) or stacking of selections)






















# Event
  - date
  - origin (Player,Server,Entity,Nobody)
  - thread (Server thread)
  - channel (info/warn)
  - data (text)
  - command (true/false)
  - processed (true/false)
  - fingerprint (string)
  - type
    - chat
    - exception
    - uauth
    - boot
    - clientstate
    - log
    - unknown
  - subtype
    - connecting/disconnecting
    - setup



# Tasks
  - run_at
  - locked_by
  - handler
