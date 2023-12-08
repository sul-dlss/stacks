# frozen_string_literal: true

###
# A class to model various authentication checks on media objects
# and return a hash to be used as JSON in a controller response
class MediaAuthenticationJson
  # @param [User] user
  # @param [StacksMediaStream] media
  # @param [String] auth_url the login url to send to the client if the user could login.
  # @param [Ability] ability the CanCan ability object
  def initialize(user:, media:, auth_url:, ability:)
    @user = user
    @media = media
    @auth_url = auth_url
    @ability = ability
  end

  # This JSON response is sent to the client when they are not authorized to view a stream.
  class DenyResponse
    def initialize(auth_url)
      @auth_url = auth_url
      @result = { status: [] }
    end

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
      result[:location] = { code: location, label: Settings.user.locations.labels.send(location) }
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
      response.add_location_restricted!(media.location) if location_grants_access?
      response.add_embargo!(media.embargo_release_date) if embargoed?
    end
  end

  def as_json(*)
    build_response.as_json
  end

  private

  attr_reader :auth_url, :media, :user, :ability

  delegate :embargoed?, :stanford_restricted?, :restricted_by_location?, to: :media

  def user_is_in_location?
    ability.can? :access, media
  end

  def stanford_grants_access?
    stanford_restricted? && !user.webauth_user
  end

  def location_grants_access?
    restricted_by_location? && !user_is_in_location?
  end
end
