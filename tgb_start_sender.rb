ENV['TZ'] = 'Europe/Kiev'

require 'telegram/bot'
require 'yaml'
require 'rufus-scheduler'
require 'Sequel'

CONFIG = YAML.load_file('config.yaml')
DB = Sequel.connect('sqlite://tgb.db')

scheduler = Rufus::Scheduler.new
bot = Telegram::Bot::Client.new(CONFIG['token'])

scheduler.cron '*/1 * * * *' do
  # Підключення до БД і формування щоденного завдання для учасників каналу
  id_daily = rand(1..DB[:words].max(:id))
  row_daily = DB[:words].where(id: id_daily).first
  uk_word_daily = row_daily[:uk_word]
  text_daily = "Доброго дня! Вишліть, будь-ласка, мені фото, на якому є #{uk_word_daily}."
  # Відправка повідомлення
  puts 'Sending message from bot to channel...'
  bot.api.send_message(chat_id: CONFIG['channel'], text: text_daily)
end

puts 'Starting scheduler...'
scheduler.join
