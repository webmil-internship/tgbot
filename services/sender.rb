class Sender
  attr_accessor :bot_token, :schedule

  def initialize
    @bot_token = CONFIG['token']
    @schedule = CONFIG['schedule']
  end

  def run
    puts 'Starting scheduler...'
    scheduler = Rufus::Scheduler.new
    ui = UserInteraction.new(Telegram::Bot::Client.new(bot_token))

    scheduler.cron schedule do
      task = Task.find(date: Date.today)
      if task.nil?
        ui.send_task
      else
        puts "#{Date.today} - today task already exists"
      end
    end
  end

end