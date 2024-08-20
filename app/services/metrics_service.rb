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

  def track_event(name, properties, user_agent:, ip:)
    headers = {
      'User-Agent': user_agent,
      'X-Forwarded-For': ip
    }

    post_json('/ahoy/events', event_data(name, properties), headers)
  end

  private

  # Schema: https://github.com/ankane/ahoy#events-1
  # NOTE: it's possible to batch events this way.
  def event_data(name, properties)
    {
      events: [
        {
          id: SecureRandom.uuid,
          time: Time.current,
          name:,
          properties:
        }
      ]
    }
  end

  def default_headers
    {
      'Content-Type': 'application/json',
      'User-Agent': Settings.user_agent
    }
  end

  def post_json(url, data, headers)
    connection.post(url) do |req|
      req.headers = default_headers.merge(headers)
      req.body = data.to_json
    end
  end

  def connection
    @connection ||= Faraday.new({ url: base_url, request: { open_timeout: 5 } })
  end
end
