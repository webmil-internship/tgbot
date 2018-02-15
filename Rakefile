require "sequel"
require 'sequel/extensions/seed'
require 'yaml'

Sequel.extension :migration
Sequel.extension :seed

CONFIG = YAML.load_file('config.yml')
DB = Sequel.connect(CONFIG['db_file'])

namespace :db do
  desc "Run migrations"
  task :migrate, [:version] do |t, args|
    if args[:version]
      puts "Migrating to version #{args[:version]}"
      Sequel::Migrator.run(DB, "db/migrate", target: args[:version].to_i)
    else
      puts "Migrating to latest"
      Sequel::Migrator.run(DB, "db/migrate")
    end
  end

  desc "Perform migration reset (full rollback and migration)"
  task :reset do
    puts "Migrating to start"
    Sequel::Migrator.run(DB, "db/migrate", :target => 0)
    puts "Migrating to latest"
    Sequel::Migrator.run(DB, "db/migrate")
  end

  desc "Perform insert seed"
  task :seed do
    Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
    puts "Inserting seeds"
    Sequel::Seeder.apply(DB, "db/seeds")
  end
end
