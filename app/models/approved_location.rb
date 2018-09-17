###
# Simple class that will return an approved location (for restricted content)
# based on a provided locatable object's IP address
class ApprovedLocation
  delegate :to_s, to: :location_for_ip
  def initialize(locatable)
    @locatable = locatable
  end

  def to_s
    return '' unless location_for_ip

    location_for_ip[0].to_s
  end

  private

  attr_reader :locatable

  def location_for_ip
    return unless locatable.try(:ip_address)

    location_configuration.find do |_, ip_addresses|
      ip_addresses.include?(locatable.ip_address)
    end
  end

  def location_configuration
    Settings.user.locations
  end
end
