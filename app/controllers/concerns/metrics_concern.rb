# frozen_string_literal: true

# Methods for logging usage metrics based on requests for files
module MetricsConcern
  def track_download(druid, file: nil)
    return unless enabled?

    ensure_visit
    properties = { druid:, file: }.compact
    metrics_service.track_event(event_data('download', properties))
  end

  private

  # We're responsible for ensuring that every event is tied to a visit
  def ensure_visit
    return if existing_visit?

    set_visit_token unless visit_token
    set_visitor_token unless visitor_token

    metrics_service.track_visit(visit_data)
  end

  # Schema: https://github.com/ankane/ahoy#visits-1
  def visit_data
    {
      visit_token:,
      visitor_token:,
      js: false
    }.merge(visit_properties)
  end

  # Schema: https://github.com/ankane/ahoy#events-1
  def event_data(name, properties = {})
    {
      visit_token:,
      visitor_token:,
      events: [
        {
          id: generate_id,
          time: Time.current,
          name:,
          properties:
        }
      ]
    }
  end

  def existing_visit?
    visit_token && visitor_token
  end

  def visit_token
    cookies[:ahoy_visit]
  end

  def visitor_token
    cookies[:ahoy_visitor]
  end

  # Sessions last for 1 hour (default used by Zenodo)
  def set_visit_token
    cookies[:ahoy_visit] = {
      value: generate_id,
      expires: 1.hour.from_now,
      domain: 'stanford.edu'
    }
  end

  # Visitors are remembered for 2 years (Ahoy's default)
  def set_visitor_token
    cookies[:ahoy_visitor] = {
      value: generate_id,
      expires: 2.years.from_now,
      domain: 'stanford.edu'
    }
  end

  # Ahoy uses UUIDs for visit/visitor/event IDs
  def generate_id
    SecureRandom.uuid
  end

  def visit_properties
    @visit_properties ||= VisitProperties.new(request).generate
  end

  def metrics_service
    @metrics_service ||= MetricsService.new
  end

  def enabled?
    Settings.features.metrics == true
  end
end
