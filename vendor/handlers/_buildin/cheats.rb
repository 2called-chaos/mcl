module Mcl
  Mcl.reloadable(:HMclCheats)
  ## Cheats (I'm not judging your wiener)
  # !l0 [target]
  # !l30 [target]
  # !l1337 [target]
  # !balls [target]
  # !boat [target]
  # !minecart [target]
  class HMclCheats < Handler
    def setup
      register_l0(:guest)
      register_l30(:mod)
      register_l1337(:mod)
      register_balls(:mod)
      register_boat(:mod)
      register_minecart(:mod)
    end

    def register_l0 acl_level
      register_command :l0, desc: "removes all levels from you or a target", acl: acl_level do |player, args|
        $mcl.server.invoke "/xp -10000L #{args.first || player}"
      end
    end

    def register_l30 acl_level
      register_command :l30, desc: "adds 30 levels to you or a target", acl: acl_level do |player, args|
        $mcl.server.invoke "/xp 30L #{args.first || player}"
      end
    end

    def register_l1337 acl_level
      register_command :l1337, desc: "sets your or target's level to 1337", acl: acl_level do |player, args|
        $mcl.server.invoke "/xp -10000L #{args.first || player}"
        $mcl.server.invoke "/xp 1337L #{args.first || player}"
      end
    end

    def register_balls acl_level
      register_command :balls, desc: "gives you or target 16 ender perls", acl: acl_level do |player, args|
        $mcl.server.invoke "/give #{args.first || player} ender_pearl 16"
      end
    end

    def register_boat acl_level
      register_command :boat, desc: "summons a boat above your or target's head", acl: acl_level do |player, args|
        $mcl.server.invoke "/execute #{args.first || player} ~ ~ ~ summon Boat ~ ~2 ~"
      end
    end

    def register_minecart acl_level
      register_command :minecart, desc: "summons a minecart above your or target's head", acl: acl_level do |player, args|
        $mcl.server.invoke "/execute #{args.first || player} ~ ~ ~ summon Minecart ~ ~2 ~"
      end
    end
  end
end
