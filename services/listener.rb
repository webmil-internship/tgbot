class Listener
  attr_accessor :bot_token

  def initialize
    @bot_token = CONFIG['token']
  end

  def run
    puts 'Starting listener...'
    Telegram::Bot::Client.run(bot_token) do |bot|
      bot.listen do |message|
        ui = UserInteraction.new(bot, message)
        if message.photo.any?
          # Перевіряємо, чи гравець зареєстрований
          next if ui.show_if_no_user?
          # Перевіряємо, чи було сьогодні вже завдання
          next if ui.show_if_no_task?
          # Перевіряємо, чи гравець вже присилав на сьогоднішню дату фото
          next if ui.show_if_is_photo?
          # Обробляємо отримане фото
          ReceivedPhoto.new(message).handling
          ui.show_photo_received
          puts "Received the photo from ID: #{message.chat.id}, Username: #{message.chat.first_name}"
         elsif message.document
          ui.show_file_is_not_photo
          puts "Received the non-photo file from ID: #{message.chat.id}, Username: #{message.chat.first_name}"
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
          when '/my_tags'
            ui.show_my_tags
          when '/short'
            ui.show_all_rate('short')
          when '/all'
            ui.show_all_rate('full')
          else
            ui.show_rules
          end
        end
      end
    end
  end

end