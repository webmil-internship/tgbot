class Sender
  attr_accessor :bot_token, :schedule, :channel

  def initialize
    @bot_token = CONFIG['token']
    @schedule = CONFIG['schedule']
    @channel = CONFIG['channel']
  end

  def run
    scheduler = Rufus::Scheduler.new
    bot = Telegram::Bot::Client.new(bot_token)

    scheduler.cron schedule do
      # Підключення до БД і формування щоденного завдання для учасників каналу
      id_daily = rand(1..Word.max(:id))
      uk_word_daily = Word.find(id: id_daily)[:uk_word]
      en_word_daily = Word.find(id: id_daily)[:en_word]
      text_daily = "Доброго дня! Вишліть, будь-ласка, мені фото, на якому є #{uk_word_daily}."
      # Відправка повідомлення
#      bot.api.send_message(chat_id: channel, text: text_daily)
      users = User.where(is_active: true)
      users.each do |u|
        bot.api.send_message(chat_id: u.user_id, text: text_daily)
      end
      puts "Sent the daily task about #{en_word_daily} from bot to users..."
      # Запис в БД інформації про денне завдання
      Task.create(:date => Date.today.to_s, :en_word => en_word_daily)
    end

    puts 'Starting scheduler...'
    scheduler.join
  end

end