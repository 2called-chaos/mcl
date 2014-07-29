module Mcl
  class Application
    module DbSchema
      def define_database_schema
        ActiveRecord::Migration.verbose = true
        ActiveRecord::Migrator.migrate Dir["#{ROOT}/**/migrations"], ENV['VERSION'].try(:to_i) ? ENV['VERSION'].to_i : nil
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
