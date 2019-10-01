namespace :pgq do
  desc "Перезалить схему pgq"
  task recreate_schema: :environment do
    raise "Don't run this task in production environment!" if Rails.env.production?

    ActiveRecord::Base.connection.execute "DROP SCHEMA IF EXISTS pgq CASCADE;"
    system %(#{PgTools.psql} < #{Rails.root}/db/pgq/schema.sql)
  end
end
