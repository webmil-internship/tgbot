require 'telegram/bot'
require 'yaml'
require 'Sequel'

CONFIG = YAML.load_file('config.yaml')
DB = Sequel.connect('sqlite://tgb.db')

puts 'Starting bot...'
Telegram::Bot::Client.run(CONFIG['token']) do |bot|
  bot.listen do |message|
    case message.text
#    when '/start'
#	     bot.api.sendMessage(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}")
#      bot.api.sendMessage(chat_id: CONFIG['channel'], text: "Ви отримали нове завдання ;)")
    when '/whoami'
      your_name = message.from.first_name
      bot.api.sendMessage(chat_id: message.chat.id, text: "You are #{your_name}")
    when '/statistic'
      #
      # Вибірка з БД статистики розпізнавання
      # фото по користувачах
      #
      bot.api.sendMessage(chat_id: message.chat.id, text: "Статистика результатів розпізнавання")
    when '/help'
      bot.api.sendMessage(chat_id: message.chat.id, text: "Нічим не можу помогти...")
    else
      bot.api.send_message(chat_id: message.chat.id, text: "Што")
    end
    if !message.document.nil?
      bot.api.send_message(chat_id: message.chat.id, text: "Файл необхідно відправляти як фото !")
    end
#    if !message.photo[0].nil?
    if message.photo.any?
      #
      # Відправка на зовнішній ресурс розпізнавання фото
      # Отримання результату та запис його в БД
      #
#      user_name = message.from.username
#      puts message.from.username
      # шукаємо, чи користувач присутній в БД
      bot.api.send_message(chat_id: message.chat.id, text: "Отримав фото, дякую !")
#      puts "Received the photo from #{message.from.username}"
    end
  end
end
