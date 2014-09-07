module Mcl
  Mcl.reloadable(:HMMclACL)
  class HMMclACL < Handler
    module Helper
      def love_player p
        trawt("@a", "ACL", {text: "I love ", color: "green"}, {text: p, color: "aqua"}, {text: " now!", color: "green"})
      end

      def perm_book p
        # @todo implement
        trawt(p, "ACL", {text: "Not yet implemented", color: "red"})
      end

      def perm_reload p, msg = true
        trawm(p, title("ACL"), {text: "Reloading ACL...", color: "gold"}) if msg
        pman.acl_reload
      end

      def grant_perm p, lvl, msg = nil
        lval = pman.lvlval(lvl)
        prec(p).permission = lval
        perm_reload(p, false)
        trawt(p, "ACL", {text: msg || "You've got #{lval} magic orbs now!", color: "green"})
        love_player(p)
      end
    end
    include Helper

    def setup
      register_op
      register_deop
      register_acl
      register_uadmin
    end

    def register_op
      register_command :op, desc: "ops you or a target (no selectors)", acl: :admin do |player, args|
        $mcl.server.invoke "/op #{args.first || player}"
      end
    end

    def register_deop
      register_command :deop, desc: "deops you or a target (no selectors)", acl: :admin do |player, args|
        $mcl.server.invoke "/deop #{args.first || player}"
      end
    end

    def register_acl
      register_command :acl, desc: "manage ACL rules/cache", acl: :admin do |player, args|
        case args[0]
        when "book" then perm_book(player)
        when "reload" then perm_reload(player)
        else
          if args.count > 1
            level = pman.lvlval(args.shift)
            acl_verify(player, level)
            args.each {|target| grant_perm target, level }
          else
            trawt(player, "ACL", {text: "!acl book ", color: "gold"}, {text: "get a perm book", color: "white"})
            trawt(player, "ACL", {text: "!acl reload ", color: "gold"}, {text: "reload permission cache", color: "white"})
            trawt(player, "ACL", {text: "!acl <lvl> <t1> [t2..] ", color: "gold"}, {text: "grant <lvl> to targets", color: "white"})
            trawt(player, "ACL", {text: "<lvl> might be an integer or a group representive.", color: "white"})
          end
        end
      end
    end

    def register_uadmin
      register_command :uadmin, desc: "Gives yourself ACL root permissions if listed as uadmin in config", acl: :guest do |player, args|
        if app.config["admins"].include?(player) || app.config["admins"].include?(prec(player).uuid)
          grant_perm player, :root, "You are root now!"
        else
          trawt(player, "ACL", {text: "No way!", color: "red"})
        end
      end
    end
  end
end
