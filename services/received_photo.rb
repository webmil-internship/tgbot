class ReceivedPhoto
  attr_accessor :tg_api_url, :mscv_url, :mscv_subkey, :bot_token, :message

  def initialize(m)
    @tg_api_url = CONFIG['tg_api_url']
    @mscv_url = CONFIG['mscv_url']
    @mscv_subkey = CONFIG['mscv_subkey']
    @bot_token = CONFIG['token']
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
    get_file_url = "#{tg_api_url}/bot#{bot_token}/getFile?file_id=#{file_id}"
    json_response = RestClient.get(get_file_url).body
    response = JSON.parse(json_response)
    file_path = response.dig("result", "file_path")
    "#{tg_api_url}/file/bot#{bot_token}/#{file_path}"
  end

  def send_to_computer_vision(file_url)
    uri = URI(mscv_url)
    uri.query = URI.encode_www_form({
      'visualFeatures' => 'Tags',
      'language' => 'en'
    })
    request = Net::HTTP::Post.new(uri.request_uri)
    request['Content-Type'] = 'application/json'
    request['Ocp-Apim-Subscription-Key'] = mscv_subkey
    request.body = "{\"url\": \"#{file_url}\"}"
    response = Net::HTTP.start(uri.host, uri.port, :use_ssl => uri.scheme == 'https') do |http|
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