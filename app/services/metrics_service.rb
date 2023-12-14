# frozen_string_literal: true

# Tracks metrics via the SDR Metrics API
# https://github.com/sul-dlss/sdr-metrics-api
#
# See also Ahoy's API spec:
# https://github.com/ankane/ahoy#api-spec
class MetricsService
  attr_reader :base_url

  def initialize(base_url: Settings.metrics_api_url)
    @base_url = base_url
  end

  def track_event(data, original_request)
    post_json('/ahoy/events', data, original_request)
  end

  private

  def post_json(url, data, original_request)
    connection.post(url) do |req|
      # Pass the original browser info and IP along to the metrics API
      req.headers['User-Agent'] = original_request.user_agent
      req.headers['X-Forwarded-For'] = original_request.remote_ip
      req.headers['Content-Type'] = 'application/json'
      req.body = data.to_json
    end
  rescue Faraday::ConnectionFailed => e
    Rails.logger.error("Error sending metrics: #{e}")
    nil
  end

  def connection
    @connection ||= Faraday.new(base_url)
  end
end
