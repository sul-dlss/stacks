class WowzaSecureToken
  def initialize(file_path:)
    @file_path = file_path
    @prefix = Settings.stream.security_token_prefix
    @uri = URI.parse Settings.stream.url
  end

  attr_reader :prefix, :uri, :file_path

  # SecureToken https://www.wowza.com/docs/how-to-protect-streaming-using-securetoken-in-wowza-streaming-engine#hls-example4
  def streaming_url
    file_part = "#{uri.path.delete_prefix('/')}/#{file_path}"
    hash_params = "#{file_part}?#{Settings.stream.security_token_secret}&#{date_param}"
    token_param = "#{prefix}hash=#{url_safe_hash(hash_params)}"
    "#{uri.scheme}://#{uri.host}/#{file_part}/playlist.m3u8?#{date_param}&#{token_param}"
  end

  private

  def date_param
    @date_param ||= "#{prefix}endtime=#{24.hours.from_now.strftime('%s')}"
  end

  def url_safe_hash(str)
    Digest::SHA256.base64digest(str).tr('+', '-').tr('/', '_')
  end
end
