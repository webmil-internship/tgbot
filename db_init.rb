require 'sequel'

DB = Sequel.connect('sqlite://tgb.db')

if DB.table_exists?(:words)
  puts "Table words already exists !"
  words = DB[:words]
  puts "Words count: #{words.count}"
  puts "Words found:"
  words.each do |w|
    puts "ID = #{w[:id]}, Ukr = #{w[:uk_word]}, Eng = #{w[:en_word]}"
  end
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
    puts "ID = #{u[:id]}, Username = #{u[:user_name]}, Active = #{u[:is_active]}"
  end
else
  DB.create_table :users do
    Integer :id
    String :user_name
    Boolean :is_active
  end
  users = DB[:users]
  users.insert(:id => 123, :user_name => 'RomanKS', :is_active => true)
  users.insert(:id => 124, :user_name => 'RomanMTS', :is_active => false)
end
