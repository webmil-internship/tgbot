class UserInteraction
  attr_accessor :bot, :message

  def initialize(b, m)
   @bot = b
   @message = m
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
  
  def no_task?
    if Task.find(date: Date.today).nil?
      bot.api.send_message(chat_id: message.chat.id, text: "Сьогодні завдання ще не було !")
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
  
  def show_task
    task = Task.find(date: Date.today)
    if task
      bot.api.sendMessage(chat_id: message.chat.id, text: "Доброго дня! Вишліть, будь-ласка, мені фото, на якому є #{task.uk_word}.")
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

end
