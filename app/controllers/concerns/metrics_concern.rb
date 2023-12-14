# frozen_string_literal: true

# Methods for logging usage metrics based on requests for files
module MetricsConcern
  def track_download(druid, file: nil)
    return unless enabled?

    properties = { druid:, file: }.compact
    metrics_service.track_event(event_data('download', properties), request)
  end

  private

  # Schema: https://github.com/ankane/ahoy#events-1
  def event_data(name, properties = {})
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

  def metrics_service
    @metrics_service ||= MetricsService.new
  end

  def enabled?
    Settings.features.metrics == true
  end
end
