require 'telegram/bot'
require 'yaml'
require 'sequel'
require 'net/http'
require 'json'
require 'rest-client'

CONFIG = YAML.load_file('config.yaml')
DB = Sequel.connect('sqlite://tgb.db')

TELEGRAM_API_PATH = 'https://api.telegram.org'.freeze
METHOD_NAME = 'getFile'.freeze
PARAM_NAME = 'file_id'.freeze

puts 'Starting bot...'
Telegram::Bot::Client.run(CONFIG['token']) do |bot|
  bot.listen do |message|
    if message.photo.any?
      # якщо учасник відсутній в таблиці users, добавляємо
      users = DB[:users]
      user_id = message.from.id
      user_uname = message.from.username
      photo = message.photo.last
      users.insert(:id => user_id, :user_name => user_uname) if DB[:users].where(id: user_id).first.nil?
      # Отримання URL завантаженого фото
      get_file_url = "#{TELEGRAM_API_PATH}/bot#{CONFIG['token']}/#{METHOD_NAME}?#{PARAM_NAME}=#{photo.file_id}"
      json_response = RestClient.get(get_file_url).body
      response = JSON.parse(json_response)
      file_path = response.dig("result", "file_path")
      file_url = "#{TELEGRAM_API_PATH}/file/bot#{CONFIG['token']}/#{file_path}"
      # Відправка на зовнішній ресурс розпізнавання фото
      uri = URI(CONFIG['mscv_url'])
      uri.query = URI.encode_www_form({
          'visualFeatures' => 'Tags',
          'language' => 'en'
      })
      request = Net::HTTP::Post.new(uri.request_uri)
      request['Content-Type'] = 'application/json'
      request['Ocp-Apim-Subscription-Key'] = CONFIG['mscv_subkey']
      request.body = "{\"url\": \"#{file_url}\"}"
      #request.body = "{\"url\": \"http://www.pravmir.ru/wp-content/uploads/2013/05/paz.jpg\"}"
      #request.body = "{\"url\": \"http://vseproauto.com/wp-content/uploads/2017/10/zovnishnist-i-dvygun-zaz-lanos-tsina-ne-vidpovidaye-ochikuvannyam.jpg\"}"
      response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
          http.request(request)
      end
      json = JSON.parse(response.body)
      tags = json["tags"]
      date_daily = DB[:tasks].max(:date)
      en_word = DB[:tasks].where(date: date_daily).first[:en_word]
      # записуємо результати розпізнавання в таблицю results
      results = DB[:results]
      tags.each do |tag|
        results.insert(:id_user => user_id, :date => date_daily, :en_word => en_word, :tag => tag["name"], :confidence => tag["confidence"])
      end
      bot.api.send_message(chat_id: message.chat.id, text: "Отримав фото, дякую !")
      puts "Received the photo from ID: #{user_id}, Username: #{user_uname}"
    elsif !message.document.nil?
      bot.api.send_message(chat_id: message.chat.id, text: "Файл необхідно відправляти як фото !")
    else
      case message.text
      when '/start'
        bot.api.sendMessage(chat_id: message.chat.id, text: "Вітаю, #{message.from.first_name}")
      when '/whoami'
        your_name = message.from.first_name
        your_uname = message.from.username
        your_id = message.from.id
        bot.api.sendMessage(chat_id: message.chat.id,
          text: "You are #{your_name}, Username -> #{your_uname}, id -> #{your_id}")
      when '/statistic'
        #
        # Вибірка з БД і формування статистики розпізнавання по користувачах
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
