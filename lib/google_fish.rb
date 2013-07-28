class GoogleFish
  attr_accessor :key, :source, :target, :q, :translated_text, :format, :supported_languages

  def initialize(key)
    @key = key
  end

  def translate(source, target, q, options={})
    @format = options[:html] ? :html : :text
    @source, @target, @q = source, target, q
    @translated_text = request_translation
  end

  def get_supported_languages(target = nil)
    @source = @format = @q = nil
    @target = target
    @supported_languages = request_supported_languages
  end

  def supported_languages
    @supported_languages ||= get_supported_languages
  end

  private

  def request_translation
    api = GoogleFish::Request.new(self)
    api.perform_translation
  end

  def request_supported_languages
    api = GoogleFish::Request.new(self)
    api.get_supported_languages
  end
end

class GoogleFish::Request
  require 'net/https'
  require 'addressable/uri'
  require 'json'
  attr_accessor :query, :response, :parsed_response

  def initialize(query)
    @query = query
  end

  def perform_translation
    @response = get
    @parsed_response = parse
  end

  def get_supported_languages
    @response = get('languages')
    @parsed_response = parse_languages
  end

  private

  def query_values
    {:key => query.key, :q => query.q, :format => query.format,
      :source => query.source, :target => query.target}
  end

  def set_uri(action = '')
    uri = Addressable::URI.new
    uri.host = 'www.googleapis.com'
    (action = action =~ /^\// ? action : '/' + action) unless action.empty?
    uri.path = '/language/translate/v2' + action
    uri.query_values = query_values.delete_if{ |k, v| v.nil? }
    uri.scheme = 'https'
    uri.port = 443
    uri
  end

  def get(action = '')
    uri = set_uri(action)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    req = Net::HTTP::Get.new(uri.request_uri)
    res = http.request(req)
    raise GoogleFish::Request::ApiError unless res.code.to_i == 200
    res.body
  end

  def parse
    body = JSON.parse(response)
    body["data"]["translations"].first["translatedText"]
  end

  def parse_languages
    body = JSON.parse(response)
    body["data"]["languages"].collect{ |l| l["language"] }
  end
end

class GoogleFish::Request::ApiError < Exception;end;
