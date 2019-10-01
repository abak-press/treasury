class CreateSchema < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute "DROP SCHEMA IF EXISTS DENORMALIZATION CASCADE;"

    system %(#{PgTools.psql} < #{File.expand_path(File.join(File.dirname(__FILE__), 'schema.sql'))})
  end

  def down
    ActiveRecord::Base.connection.execute "DROP SCHEMA IF EXISTS DENORMALIZATION CASCADE;"
  end
end
