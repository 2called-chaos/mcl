module Mcl
  class Application
    module DbSchema
      def define_database_schema
        ActiveRecord::Migration.verbose = true
        connection_pool = ActiveRecord::Base.connection_pool
        schema_migration = ActiveRecord::SchemaMigration.new(connection_pool)
        internal_metadata = ActiveRecord::InternalMetadata.new(connection_pool)
        migration_context = ActiveRecord::MigrationContext.new(Dir["#{ROOT}/**/migrations"], schema_migration, internal_metadata)
        missing = migration_context.open.pending_migrations
        log.debug "[Migrator] found #{migration_context.migrations.count} migrations, #{missing.count} yet to migrate."

        if missing.any?
          # create backup of sqlite DB
          if config["database"]["adapter"] == "sqlite3"
            log.debug "[Migrator] creating backup of sqlite DB"
            FileUtils.cp(@config["database"]["database"], "#{@config["database"]["database"]}.#{Time.current.strftime("%Y-%m-%d_%H-%M-%S")}.backup")
          end

          log.debug "[Migrator] migrating #{missing.count} migrations..."
          migration_context.up
        end
      end

      # def define_database_schema
      #   ActiveRecord::Schema.define do
      #     unless ActiveRecord::Base.connection.tables.include? 'albums'
      #       create_table :albums do |table|
      #         table.column :title, :string
      #         table.column :performer, :string
      #       end
      #     end
      #   end
      # end
    end
  end
end
