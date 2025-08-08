# frozen_string_literal: true

###
# Simple class that will return an approved location (for restricted content)
# based on a provided user's IP address
class ApprovedLocation
  delegate :to_s, to: :location_for_ip
  def initialize(user)
    @user = user
  end

  def locations
    location_configuration.select do |_, ip_addresses|
      ip_addresses.include?(user.ip_address)
    end.keys.map(&:to_s)
  end

  private

  attr_reader :user

  def location_for_ip
    locations.first
  end

  def location_configuration
    Settings.user.locations.to_h
  end
end
