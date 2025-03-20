# frozen_string_literal: true

# Represents IIIF Auth V2 probe service response
# See https://iiif.io/api/auth/2.0/#probe-service-response
class AuthProbeResult2
  def initialize(status:, note: nil)
    @status = status
    @note = note
  end

  attr_reader :status, :note

  def as_json
    json = { '@context': 'http://iiif.io/api/auth/2/context.json', type: 'AuthProbeResult2', status: status }
    json[:note] = note if note
    json
  end

  # When redirecting to a different resource.
  class LocationResult < AuthProbeResult2
    def initialize(location:, **)
      super(status: 302)
      @location = location
    end

    attr_reader :location

    def as_json
      super.merge(location:)
    end
  end

  # When not authorized to view the resource.
  class ErrorResult < AuthProbeResult2
    def initialize(heading:, icon: nil, **)
      super(status: 401, **)
      @heading = heading
      @icon = icon
    end

    attr_reader :heading, :icon

    def as_json
      super.merge(heading:, icon:)
    end
  end

  def self.ok
    new(status: 200)
  end

  def self.bad_request(messages)
    new(status: 400, note: { en: messages })
  end

  # return 403 since there is nothing a user can do to get access
  # IIIF has the API return 401 for views that can be logged into,
  # which we don't want for no_download, embargo with no stanford login, location restricted
  # https://iiif.io/api/auth/2.0/#71-authorization-flow-algorithm
  def self.forbidden(heading:, icon:)
    ErrorResult.new(status: 403, note: { en: [I18n.t('probe_service.access_restricted')] }, heading: { en: [heading] }, icon:)
  end

  def self.unauthorized(heading:, icon:)
    ErrorResult.new(note: { en: [I18n.t('probe_service.access_restricted')] }, heading: { en: [heading] }, icon:)
  end

  def self.not_found(druid)
    new(status: 404, note: { en: ["Unable to find #{druid}"] })
  end

  # See https://iiif.io/api/auth/2.0/#location
  def self.redirect(location)
    LocationResult.new(location:)
  end
end
