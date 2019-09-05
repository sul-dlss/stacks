# frozen_string_literal: true

###
# Simple class that will return an approved location (for restricted content)
# based on a provided locatable object's IP address
class ApprovedLocation
  delegate :to_s, to: :location_for_ip
  def initialize(locatable)
    @locatable = locatable
  end

  def locations
    return [] unless locatable.try(:ip_address)

    location_configuration.select do |_, ip_addresses|
      ip_addresses.include?(locatable.ip_address)
    end.keys.map(&:to_s)
  end

  private

  attr_reader :locatable

  def location_for_ip
    locations.first
  end

  def location_configuration
    Settings.user.locations.to_h
  end
end
