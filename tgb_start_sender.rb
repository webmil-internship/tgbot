require 'telegram/bot'
require 'yaml'
require 'rufus-scheduler'

CONFIG = YAML.load_file('config.yaml')

scheduler = Rufus::Scheduler.new
bot = Telegram::Bot::Client.new(CONFIG['token'])

scheduler.cron '*/1 * * * *' do
  # Підключення до БД і формування
  # щоденного завдання для учасників каналу
  puts 'Sending message from bot to channel...'
  bot.api.send_message(chat_id: CONFIG['channel'], text: "Щохвилинне повідомлення від Рубі-бота :)")
end

puts 'Starting scheduler...'
scheduler.join
