class UserInteraction
  attr_accessor :bot, :message
  
  PHOTO_RECEIVED = "Ваше фото отримав, дякую !"
  FILE_IS_NOT_PHOTO = "Файл необхідно відправляти як фото !"

  def initialize(b, m = nil)
    @bot = b
    @message = m
  end

  def show_if_no_user?
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
  
  def show_if_no_task?
    if Task.find(date: Date.today).nil?
      bot.api.send_message(chat_id: message.chat.id, text: "Сьогодні завдання ще не було !")
      true
    else
      false
    end
  end

  def show_if_is_photo?
    if Result.where(id_user: message.from.id, date: Date.today).any?
      bot.api.send_message(chat_id: message.chat.id, text: "На сьогоднішнє завдання Ви вже присилали фото !")
      true
    else
      false
   end
  end

  def show_rules
    bot.api.send_message(chat_id: message.chat.id,
      text: "Правила гри:\n
          - Для реєстрації або поновлення в грі - /start\n
          - Для зупинки участі в грі - /stop\n
          - Сьогоднішнє завдання - /task\n
          - Статистика всіх учасників - /all\n
          - Статистика всіх учасників (коротка) - /short\n
          - Ваша статистика - /my\n
          - Для перегляду цих правил - будь-який текст\n
          Успіхів !\n")
  end
  
  def show_photo_received
    bot.api.send_message(chat_id: message.chat.id, text: PHOTO_RECEIVED)
  end
  
  def show_file_is_not_photo
    bot.api.send_message(chat_id: message.chat.id, text: FILE_IS_NOT_PHOTO)
  end
  
  def show_task
    task = Task.find(date: Date.today)
    if task
      bot.api.sendMessage(chat_id: message.chat.id, text: "Вишліть, будь-ласка, мені фото, на якому є #{task.uk_word}.")
    else
      bot.api.sendMessage(chat_id: message.chat.id, text: "Сьогодні завдання ще не було !")
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
    show_task unless show_if_is_photo?
  end

  def remove_user
    user = User.find(user_id: message.from.id)
    if user.nil?
      bot.api.sendMessage(chat_id: message.chat.id, text: "Ви не зареєстровані в грі, #{message.from.username} !")
      show_rules
    elsif user.is_active == true
      user.update(is_active: false)
      bot.api.sendMessage(chat_id: message.chat.id, text: "Шкода, що Ви покидаєте гру, #{message.from.username} !")
    else
      bot.api.sendMessage(chat_id: message.chat.id, text: "Ви вже покинули гру, #{message.from.username} !")
    end
  end

  def old_show_my_rate
    text = ""
    results = Result.where(id_user: message.from.id, en_word: :tag).order(:date)
    days_all = Result.where(id_user: message.from.id).group(:date).count
    days_right = Result.where(id_user: message.from.id, en_word: :tag).group(:date).count
    confidence_sum = Result.where(id_user: message.from.id, en_word: :tag).sum(:confidence)
    confidence_avr = confidence_sum / days_all
    results.each do |row|
      text += "#{row[:date]} #{row[:en_word].ljust(10)}: #{row[:confidence]}\n"
    end
    text += "Дні участі/співпадіння: #{days_all}/#{days_right}\n"
    text += "Середня оцінка співпадіння: #{confidence_avr}"
    bot.api.send_message(chat_id: message.chat.id, text: text)
  end

  def show_my_rate
    text = ""
    days_all = Result.where(id_user: message.from.id).group(:date).count
    days_right = Result.where(id_user: message.from.id, en_word: :tag).group(:date).count
    confidence_sum = Result.where(id_user: message.from.id, en_word: :tag).sum(:confidence)
    confidence_avr = confidence_sum / days_all
    Task.order(:date).each do |row|
      attempt = Result.where(id_user: message.from.id, date: row[:date]).count
      result = Result.where(id_user: message.from.id, date: row[:date], tag: row[:en_word])
      text += "#{row[:date]} #{row[:en_word].ljust(10)}: #{result.first.nil? ? "0.00" : result.first[:confidence]}\n" if attempt > 0
    end
    text += "Дні участі/співпадіння: #{days_all}/#{days_right}\n"
    text += "Середня оцінка співпадіння: #{confidence_avr}"
    bot.api.send_message(chat_id: message.chat.id, text: text)
  end

  def show_all_rate(how_to_show)
    user = ""
    text = ""
    resuts = Result.join(:users, user_id: :id_user).where(en_word: :tag).order(:user_name, :date)
    resuts.each do |row|
      if user != row[:user_name]
        user = row[:user_name]
        bot.api.send_message(chat_id: message.chat.id, text: text) unless text.empty?
        days_all = Result.where(id_user: row[:id_user]).group(:date).count
        days_right = Result.where(id_user: row[:id_user], en_word: :tag).group(:date).count
        confidence_sum = Result.where(id_user: row[:id_user], en_word: :tag).sum(:confidence)
        confidence_avr = confidence_sum / days_all
        text = "Учасник: #{row[:user_name]}\n"
        text += "Дні участі/співпадіння: #{days_all}/#{days_right}\n"
        text += "Середня оцінка співпадіння: #{confidence_avr}\n"
      end
      text += "#{row[:date]} #{row[:en_word].ljust(10)}: #{row[:confidence]}\n" if how_to_show == 'full'
    end
    bot.api.send_message(chat_id: message.chat.id, text: text) unless text.empty?
  end

  def send_task
    # Підключення до БД і формування щоденного завдання для учасників гри
    id_daily = rand(1..Word.max(:id))
    uk_word_daily = Word.find(id: id_daily)[:uk_word]
    en_word_daily = Word.find(id: id_daily)[:en_word]
    text_daily = "Доброго дня! Вишліть, будь-ласка, мені фото, на якому є #{uk_word_daily}."
    # Відправка повідомлення
    users = User.where(is_active: true)
    users.each do |u|
      bot.api.send_message(chat_id: u.user_id, text: text_daily)
    end
    # Запис в БД інформації про денне завдання
    Task.create(date: Date.today, en_word: en_word_daily, uk_word: uk_word_daily)
    puts "Sent the daily task about #{en_word_daily} from bot to users..."
  end

end
