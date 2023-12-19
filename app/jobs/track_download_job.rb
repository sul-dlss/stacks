# frozen_string_literal: true

# Track a single download event by sending a request to the metrics API
class TrackDownloadJob < ApplicationJob
  queue_as :default

  rescue_from StandardError do |exception|
    Rails.logger.error("Error sending metrics: #{exception}")
  end

  def perform(druid:, user_agent:, ip:, file: nil)
    return true unless Settings.features.metrics == true

    properties = { druid:, file: }.compact

    MetricsService.new.track_event('download', properties, user_agent:, ip:)
  end
end
