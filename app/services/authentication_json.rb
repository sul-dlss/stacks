# frozen_string_literal: true

###
# A generic class to model various authentication checks on files/media/etc
class AuthenticationJson
  # @param [User] user
  # @param [StacksMediaStream|StacksFile] file or media
  # @param [String] auth_url the login url to send to the client if the user could login.
  # @param [Ability] ability the CanCan ability object
  def initialize(user:, file:, auth_url:, ability:)
    @user = user
    @file = file
    @auth_url = auth_url
    @ability = ability
  end

  # This JSON response is sent to the client when they are not authorized to view a stream.
  class DenyResponse
    def initialize(auth_url)
      @auth_url = auth_url
      @result = { status: [] }
    end

    # Codes from https://github.com/sul-dlss/cocina-models/blob/8fc7b5b9b0e3592a5c81f4c0e4ebff5c926669c6/openapi.yml#L1330-L1339
    # labels from https://consul.stanford.edu/display/chimera/Rights+Metadata+Locations
    LOCATION_LABELS = {
      'spec' => 'Special Collections reading room',
      'music' => 'Music Library - main area',
      'ars' => 'Archive of Recorded Sound listening room',
      'art' => 'Art Library',
      'hoover' => 'Hoover Library',
      'm&m' => 'Media & Microtext'
    }.freeze

    attr_reader :result, :auth_url

    def as_json
      result.compact_blank
    end

    def stanford_restricted?
      status.include?(:stanford_restricted)
    end

    def add_stanford_restricted!
      add_status(:stanford_restricted)
      result[:service] = login_service
    end

    def add_location_restricted!(location)
      add_status(:location_restricted)
      result[:location] = { code: location, label: LOCATION_LABELS.fetch(location) }
    end

    def add_embargo!(embargo_release_date)
      add_status(:embargoed)
      result[:embargo] = { release_date: embargo_release_date }
    end

    private

    def add_status(status)
      result[:status] << status
    end

    def login_service
      {
        '@id' => auth_url,
        'label' => 'Stanford-affiliated? Login to play'
      }
    end
  end

  def build_response
    DenyResponse.new(auth_url).tap do |response|
      response.add_stanford_restricted! if stanford_grants_access?
      response.add_location_restricted!(file.location) if location_grants_access?
      response.add_embargo!(file.embargo_release_date) if embargoed?
    end
  end

  def as_json(*)
    build_response.as_json
  end

  private

  attr_reader :auth_url, :user, :ability, :file

  delegate :embargoed?, :stanford_restricted?, :restricted_by_location?, to: :file

  def user_is_in_location?
    ability.can? :access, file
  end

  def stanford_grants_access?
    stanford_restricted? && !user.webauth_user
  end

  def location_grants_access?
    restricted_by_location? && !user_is_in_location?
  end
end
