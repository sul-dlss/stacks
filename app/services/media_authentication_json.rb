# frozen_string_literal: true

###
# A class to model various authentication checks on media objects
# and return a hash to be used as JSON in a controller response
class MediaAuthenticationJson
  def initialize(user:, media:, auth_url:, ability:)
    @user = user
    @media = media
    @auth_url = auth_url
    @ability = ability
  end

  def as_json(*)
    return stanford_or_location_restricted_json if location_grants_access? && stanford_grants_access?
    return location_only_restricted_json if location_grants_access?
    return stanford_only_restricted_json if stanford_grants_access?

    {}
  end

  private

  attr_reader :auth_url, :media, :user, :ability

  def location_only_restricted_json
    {
      status: [:location_restricted]
    }
  end

  def stanford_only_restricted_json
    {
      status: [:stanford_restricted]
    }.merge(login_service)
  end

  def stanford_or_location_restricted_json
    {
      status: [
        :stanford_restricted,
        :location_restricted
      ]
    }.merge(login_service)
  end

  def login_service
    {
      service: {
        '@id' => auth_url,
        'label' => 'Stanford-affiliated? Login to play'
      }
    }
  end

  def stanford_restricted?
    media.stanford_restricted?
  end

  def location_restricted?
    media.restricted_by_location?
  end

  def user_is_in_location?
    ability.can? :access, media
  end

  def stanford_grants_access?
    stanford_restricted? && !user.webauth_user
  end

  def location_grants_access?
    location_restricted? && !user_is_in_location?
  end
end
