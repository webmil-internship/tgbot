class Listener
  attr_accessor :bot_token, :tg_api_url, :mscv_url, :mscv_subkey

  def initialize
    @bot_token = CONFIG['token']
    @tg_api_url = CONFIG['tg_api_url']
    @mscv_url = CONFIG['mscv_url']
    @mscv_subkey = CONFIG['mscv_subkey']
  end

  def run
    puts 'Starting bot...'
    Telegram::Bot::Client.run(bot_token) do |bot|
      bot.listen do |message|
        user_id = message.from.id
        user_name = message.from.username
        user_first_name = message.from.first_name
        if message.photo.any?
          # Отримання URL завантаженого фото
          photo = message.photo.last
          get_file_url = "#{tg_api_url}/bot#{bot_token}/getFile?file_id=#{photo.file_id}"
          json_response = RestClient.get(get_file_url).body
          response = JSON.parse(json_response)
          file_path = response.dig("result", "file_path")
          file_url = "#{tg_api_url}/file/bot#{bot_token}/#{file_path}"
          # Відправка на зовнішній ресурс розпізнавання фото
          uri = URI(mscv_url)
          uri.query = URI.encode_www_form({
              'visualFeatures' => 'Tags',
              'language' => 'en'
          })
          request = Net::HTTP::Post.new(uri.request_uri)
          request['Content-Type'] = 'application/json'
          request['Ocp-Apim-Subscription-Key'] = mscv_subkey
          request.body = "{\"url\": \"#{file_url}\"}"
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
            user = User.find_or_create(user_id: user_id) { |u| u.user_name = user_name}
            user.is_active = true
            user.save
            bot.api.sendMessage(chat_id: message.chat.id, text: "Вітаю в грі, #{user_name} !")
          when '/stop'
            user = User.find(user_id: user_id)
            if !user.nil?
              user.is_active = false
              user.save
              bot.api.sendMessage(chat_id: message.chat.id, text: "Шкода, що Ви покидаєте гру, #{user_name} !")
            end
          when '/whoami'
            bot.api.sendMessage(chat_id: message.chat.id,
              text: "Ви - #{user_first_name}, Username -> #{user_name}, id -> #{user_id}")
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
  end

end