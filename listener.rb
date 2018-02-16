require_relative 'services/user_interaction'

class Listener
  attr_accessor :bot_token, :tg_api_url, :mscv_url, :mscv_subkey, :bot, :message

  def initialize
    @bot_token = CONFIG['token']
    @tg_api_url = CONFIG['tg_api_url']
    @mscv_url = CONFIG['mscv_url']
    @mscv_subkey = CONFIG['mscv_subkey']
  end

  def run
    puts 'Starting bot...'
    Telegram::Bot::Client.run(bot_token) do |b|
      b.listen do |m|
        @bot = b
        @message = m
        ui = UserInteraction.new(b, m)
        if message.photo.any?
          # Перевіряємо, чи гравець зареєстрований
          next if ui.no_user?
          # Перевіряємо, чи було сьогодні вже завдання
          next if ui.no_task?
          # Перевіряємо, чи гравець вже присилав на сьогоднішню дату фото
          next if ui.is_photo?
          # Отримання URL завантаженого фото
          file_url = get_url(message.photo.last.file_id)
          # Відправка на зовнішній ресурс розпізнавання фото
          tags = send_to_cv(file_url)
          # записуємо результати розпізнавання в таблицю results
          save_result(tags)
        elsif message.document
          bot.api.send_message(chat_id: message.chat.id, text: "Файл необхідно відправляти як фото !")
        else
          case message.text
          when '/start'
            ui.add_user
            #ui.add_user
          when '/stop'
            ui.remove_user
          when '/task'
            ui.show_task
          when '/my'
            ui.show_my_rate
          when '/rate'
            ui.show_all_rate
          else
            ui.show_rules
          end
        end
      end
    end
  end

  private

    def get_url(file_id)
      get_file_url = "#{tg_api_url}/bot#{bot_token}/getFile?file_id=#{file_id}"
      json_response = RestClient.get(get_file_url).body
      response = JSON.parse(json_response)
      file_path = response.dig("result", "file_path")
      "#{tg_api_url}/file/bot#{bot_token}/#{file_path}"
    end

    def send_to_cv(file_url)
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
      json["tags"]
    end

    def save_result(tags)
      en_word = Task.find(date: Date.today).en_word
      tags.each do |tag|
        Result.create(id_user: message.from.id, date: Date.today, en_word: en_word, tag: tag["name"], confidence: tag["confidence"])
      end
      bot.api.send_message(chat_id: message.chat.id, text: "Отримав Ваше фото, дякую !")
      puts "Received the photo from ID: #{message.chat.id}, Username: #{message.chat.username}"
    end

end