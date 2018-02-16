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
        if message.photo.any?
          # Перевіряємо, чи гравець зареєстрований
          next if no_user?
          # Перевіряємо, чи було сьогодні вже завдання
          next if no_task?
          # Перевіряємо, чи гравець вже присилав на сьогоднішню дату фото
          next if is_photo?
          # Отримання URL завантаженого фото
          file_url = get_url(message.photo.last.file_id)
          # Відправка на зовнішній ресурс розпізнавання фото
          tags = send_to_cv(file_url)
          # записуємо результати розпізнавання в таблицю results
          save_result(tags)
        elsif !message.document.nil?
          bot.api.send_message(chat_id: message.chat.id, text: "Файл необхідно відправляти як фото !")
        else
          case message.text
          when '/start'
            add_user
          when '/stop'
            remove_user
          when '/task'
            show_task
          when '/my'
            show_my_rate
          when '/rate'
            show_all_rate
          else
            show_rules
          end
        end
      end
    end
  end

  private
    def no_task?
      if Task.find(date: Date.today).nil?
        bot.api.send_message(chat_id: message.chat.id, text: "Сьогодні завдання ще не було !")
        true
      else
        false
      end
    end

    def no_user?
      user = User.find(user_id: message.from.id)
      if user.nil?
        bot.api.sendMessage(chat_id: message.chat.id, text: "Ви не зареєстровані в грі, #{message.from.username} !")
        show_rules
        true
      elsif user.is_active == false
        bot.api.sendMessage(chat_id: message.chat.id, text: "Ви призупинили участь в грі, #{message.from.username} !")
        show_rules
        true
      else
        false
      end
    end

    def is_photo?
      if Result.where(id_user: message.from.id, date: Date.today).any?
        bot.api.send_message(chat_id: message.chat.id, text: "На сьогоднішнє завдання ви вже присилали фото !")
        true
      else
        false
      end
    end

    def add_user
      user = User.find(user_id: message.from.id)
      if user.nil?
        User.create(user_id: message.from.id, user_name: message.from.username, is_active: true)
        bot.api.sendMessage(chat_id: message.chat.id, text: "Вітаю в грі, #{message.from.username} !")
      elsif user.is_active == false
        user.update(is_active: true)
        bot.api.sendMessage(chat_id: message.chat.id, text: "З поверненням в гру, #{message.from.username} !")
      else
        bot.api.sendMessage(chat_id: message.chat.id, text: "Ви вже з нами, #{message.from.username} !")
      end
      show_task unless is_photo?
    end

    def remove_user
      user = User.find(user_id: message.from.id)
      if user.nil?
        bot.api.sendMessage(chat_id: message.chat.id, text: "Ви не зареєстровані в грі, #{message.from.username} !")
        show_rules
      else
        user.update(is_active: false)
        bot.api.sendMessage(chat_id: message.chat.id, text: "Шкода, що Ви покидаєте гру, #{message.from.username} !")
      end
    end

    def show_task
      task = Task.find(date: Date.today)
      if task
        bot.api.sendMessage(chat_id: message.chat.id, text: "Доброго дня! Вишліть, будь-ласка, мені фото, на якому є #{task.uk_word}.")
      else
        bot.api.sendMessage(chat_id: message.chat.id, text: "Сьогодні завдання ще не було !")
      end
    end

    def show_my_rate
      resuts = Result.where(id_user: message.from.id, en_word: :tag).order(:date)
      resuts.each do |row|
        bot.api.send_message(chat_id: message.chat.id, text: "#{row[:date]} #{row[:en_word]} == #{row[:tag]}:\n #{row[:confidence]}")
      end
    end

    def show_all_rate
      user = ""
      resuts = Result.join(:users, user_id: :id_user).where(en_word: :tag).order(:user_name, :date)
      resuts.each do |row|
        if user != row[:user_name]
          bot.api.send_message(chat_id: message.chat.id, text: "Учасник: #{row[:user_name]}")
          user = row[:user_name]
        end
        bot.api.send_message(chat_id: message.chat.id, text: "#{row[:date]} #{row[:en_word]} == #{row[:tag]}:\n #{row[:confidence]}")
      end
    end

    def show_rules
      bot.api.send_message(chat_id: message.chat.id,
       text: "Правила гри:\n
              - Для реєстрації або поновлення в грі - /start\n
              - Для зупинки участі в грі - /stop\n
              - Сьогоднішнє завдання - /task\n
              - Статистика всіх учасників - /rate\n
              - Ваша статистика - /my\n
              - Для перегляду цих правил - будь-який текст\n
              Успіхів !\n")
    end

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