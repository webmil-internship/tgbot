require_relative 'application_service'

class TelegramImagePath < ApplicationService
  TELEGRAM_API_PATH = 'https://api.telegram.org'.freeze
  METHOD_NAME = 'getFile'.freeze
  PARAM_NAME = 'file_id'.freeze

  def initialize(file_id = '')
    @token = ENV['TELEGRAM_TOKEN']
    @file_id = file_id
  end

  def call
    return if file_id.empty?
    responce = Oj.load(RestClient.get(get_file_url).body)

    return responce unless responce['ok']

    file_url(responce.dig('result', 'file_path'))
  end

  private
    attr_accessor :token, :file_id

    def get_file_url
      "#{TELEGRAM_API_PATH}/bot#{token}/#{METHOD_NAME}?#{PARAM_NAME}=#{file_id}"
    end

    def file_url(file_path)
        "#{TELEGRAM_API_PATH}/file/bot#{token}/#{file_path}"
    end
end
