# frozen_string_literal: true

# Properties of a user's session that are useful for tracking SDR metrics
#
# Adapted from: lib/ahoy/visit_properties.rb
# https://github.com/ankane/ahoy/blob/master/lib/ahoy/visit_properties.rb
class VisitProperties
  attr_reader :request, :params, :referrer, :landing_page

  def initialize(request)
    @request = request
    @params = request.params
    @referrer = request.referer || ''
    @landing_page = request.original_url
  end

  def generate
    @generate ||= request_properties.merge(tech_properties)
  end

  private

  def request_properties
    {
      ip:,
      user_agent:,
      referrer:,
      referring_domain:,
      landing_page:
    }
  end

  def tech_properties
    client = DeviceDetector.new(user_agent)

    # Convert device type to Ahoy's style
    device_type =
      case client.device_type
      when 'smartphone' then 'Mobile'
      when 'tv' then 'TV'
      else client.device_type&.titleize
      end

    {
      browser: client.name,
      os: client.os_name,
      device_type:
    }
  end

  def referring_domain
    return if referrer.blank?

    URI.parse(referrer).host.first(255)
  rescue URI::InvalidURIError
    nil
  end

  # Mask IPs by zeroing last octet (IPv4) or 80 bits (IPv6)
  # Based on Google Analytics' IP masking
  # https://support.google.com/analytics/answer/2763052
  def ip
    addr = IPAddr.new(@request.remote_ip)
    addr.ipv4? ? addr.mask(24).to_s : addr.mask(48).to_s
  end

  # User agents don't need to be valid UTF-8, but we would like them to be
  def user_agent
    @request.user_agent.encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  end
end
