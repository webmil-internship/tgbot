ENV['TZ'] = 'Europe/Kiev'

require 'telegram/bot'
require 'yaml'
require 'rufus-scheduler'
require 'sequel'
require 'date'
require 'net/http'
require 'json'
require 'rest-client'

CONFIG = YAML.load_file('config.yml')
DB = Sequel.connect('sqlite://./db/tgb.db')

Dir[File.dirname(__FILE__) + '/models/*.rb'].each {|file| require file }
