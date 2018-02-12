require 'telegram/bot'
require 'yaml'
require 'sequel'

CONFIG = YAML.load_file('config.yaml')
DB = Sequel.connect('sqlite://tgb.db')

puts 'Starting bot...'
Telegram::Bot::Client.run(CONFIG['token']) do |bot|
  bot.listen do |message|
    if message.photo.any?
      #
      # Відправка на зовнішній ресурс розпізнавання фото
      # Отримання результату та запис його в БД
      #
      your_name = message.from.first_name
      your_uname = message.from.username
      your_id = message.from.id
      # шукаємо, чи користувач присутній в БД
      bot.api.send_message(chat_id: message.chat.id, text: "Отримав фото від #{your_name}, дякую !")
      puts "Received the photo from ID: #{your_id}, Username: #{your_uname}"
    elsif !message.document.nil?
      bot.api.send_message(chat_id: message.chat.id, text: "Файл необхідно відправляти як фото !")
    else
      case message.text
      when '/start'
        bot.api.sendMessage(chat_id: message.chat.id, text: "Hello, #{message.from.first_name}")
#        bot.api.sendMessage(chat_id: CONFIG['channel'], text: "Ви отримали нове завдання ;)")
      when '/whoami'
        your_name = message.from.first_name
        your_uname = message.from.username
        your_id = message.from.id
        bot.api.sendMessage(chat_id: message.chat.id,
          text: "You are #{your_name}, Username -> #{your_uname}, id -> #{your_id}")
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
    end
  end
end
