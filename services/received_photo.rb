class ReceivedPhoto
  attr_accessor :message
  TG_API_URL = CONFIG['tg_api_url']
  MSCV_URL = CONFIG['mscv_url']
  MSCV_SUBKEY = CONFIG['mscv_subkey']
  BOT_TOKEN = CONFIG['token']

  def initialize(m)
    @message = m
  end

  def handling
    # Отримання URL завантаженого фото
    file_url = get_photo_url(message.photo.last.file_id)
    # Відправка на зовнішній ресурс розпізнавання фото
    tags = send_to_computer_vision(file_url)
    # записуємо результати розпізнавання в таблицю results
    save_result(tags)
  end

  private

  def get_photo_url(file_id)
    get_file_url = "#{TG_API_URL}/bot#{BOT_TOKEN}/getFile?file_id=#{file_id}"
    json_response = RestClient.get(get_file_url).body
    response = JSON.parse(json_response)
    file_path = response.dig("result", "file_path")
    "#{TG_API_URL}/file/bot#{BOT_TOKEN}/#{file_path}"
  end

  def send_to_computer_vision(file_url)
    uri = URI(MSCV_URL)
    uri.query = URI.encode_www_form({
      visualFeatures: 'Tags',
      language: 'en'
    })
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request['Ocp-Apim-Subscription-Key'] = MSCV_SUBKEY
    request.body = "{\"url\": \"#{file_url}\"}"
    response = Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == 'https') do |http|
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
  end

end