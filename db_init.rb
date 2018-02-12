require 'sequel'

DB = Sequel.connect('sqlite://tgb.db')

if DB.table_exists?(:words)
  puts "Table words already exists !"
  words = DB[:words]
else
  DB.create_table :words do
    primary_key :id
    String :uk_word
    String :en_word
  end
  words = DB[:words]
  words.insert(:uk_word => 'автомобіль', :en_word => 'car')
  words.insert(:uk_word => 'автобус', :en_word => 'bus')
  words.insert(:uk_word => 'дерево', :en_word => 'tree')
  words.insert(:uk_word => 'чашка', :en_word => 'cup')
  words.insert(:uk_word => 'стіл', :en_word => 'table')
end

if DB.table_exists?(:users)
  puts "Table users already exists !"
  users = DB[:users]
  puts "Users count: #{users.count}"
  puts "Users found:"
  users.each do |u|
    puts "ID = #{u[:id]}, Username = #{w[:user_name]}"
  end
else
  DB.create_table :users do
    primary_key :id
    String :user_name
  end
end
