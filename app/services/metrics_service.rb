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

  def track_visit(data)
    post_json('/ahoy/visits', data)
  end

  def track_event(data)
    post_json('/ahoy/events', data)
  end

  private

  def post_json(url, data)
    connection.post(url) do |req|
      req.headers['Content-Type'] = 'application/json'
      req.headers['Ahoy-Visit'] = data[:visit_token]
      req.headers['Ahoy-Visitor'] = data[:visitor_token]
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
