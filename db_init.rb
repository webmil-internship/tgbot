require 'sequel'

DB = Sequel.connect('sqlite://tgb.db')

#
# Слова
#
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
    String :uk_word   # Українською, для розсилки учасникам
    String :en_word   # Англійською, для відсилки для розпізнавання
  end
  words = DB[:words]
  words.insert(:uk_word => 'автомобіль', :en_word => 'car')
  words.insert(:uk_word => 'автобус', :en_word => 'bus')
  words.insert(:uk_word => 'дерево', :en_word => 'tree')
  words.insert(:uk_word => 'чашка', :en_word => 'cup')
  words.insert(:uk_word => 'стіл', :en_word => 'table')
end

#
# Учасники
#
if DB.table_exists?(:users)
  puts "Table users already exists !"
  users = DB[:users]
  puts "Users count: #{users.count}"
  puts "Users found:"
  users.each do |u|
    puts "ID = #{u[:id]}, Username = #{u[:user_name]}"
  end
else
  DB.create_table :users do
    Integer :id
    String :user_name   # імя користувача
#    Boolean :is_active  # ознака участі в грі
  end
  users = DB[:users]
end

#
# Щоденні завдання
#
if DB.table_exists?(:tasks)
  puts "Table tasks already exists !"
  tasks = DB[:tasks]
  puts "Tasks count: #{tasks.count}"
  puts "Tasks found:"
  tasks.each do |t|
    puts "ID = #{t[:date]}, ID word = #{t[:id_word]}"
  end
else
  DB.create_table :tasks do
    String :date      # Дата завдання
    Integer :id_word  # ID слова
  end
  tasks = DB[:tasks]
end

#
# Результати розпізнавання
#
if DB.table_exists?(:results)
  puts "Table results already exists !"
  results = DB[:results]
  puts "Results count: #{results.count}"
  puts "Results found:"
  results.each do |r|
    puts "ID = #{r[:id_user]}, ID word = #{r[:date_task]}, tag = #{r[:tag]}, confidence = #{r[:confidence]}"
  end
else
  DB.create_table :results do
    Integer :id_user
    String  :date_task
    String  :tag        # тег ідентифікації
    Float   :confidence # точність тега
  end
end
