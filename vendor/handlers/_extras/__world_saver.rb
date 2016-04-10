module Mcl
  Mcl.reloadable(:HMclWorldSaver)
  ## Invokes /save-all before stopping the server
  ## (vanilla does this by default unless deactivated)
  class HMclWorldSaver < Handler
    # Maximum time to wait for response (IN TICKS!!!!)
    # Default ticktime is 0.25 seconds
    WAIT_TICKS = 20

    def setup
      register_parser(/^Saved the world/i) { $world_saver_world_saved = true }

      # execute before minecraft server stops
      app.ipc_early :world_saver_hook do
        app.log.info "[WorldSaver] Saving worlds..."

        begin
          # invoke /save-all
          app.server.invoke "/save-all"

          # Craft a promise
          $world_saver_world_saved = false
          p = promise do |pr|
            pr.condition { $world_saver_world_saved }
            pr.callback {}
          end
          p.opts[:tries] = WAIT_TICKS * 10
          p.opts[:ticks] = WAIT_TICKS

          # continue ticking until our promise was processed
          app.eman.tick!(false) while p.alive?

          # warn if we didn't get a response
          unless $world_saver_world_saved
            app.log.warn "[WorldSaver] Didn't get a response within #{WAIT_TICKS} ticks, moving on..."
          end
        rescue Errno::EPIPE
          app.log.warn "[WorldSaver] Couldn't perform a world save because the minecraft server is gone already..."
        ensure
          $world_saver_world_saved = false
        end
      end
    end
  end
end
