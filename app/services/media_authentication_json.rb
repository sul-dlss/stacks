###
# A class to model various authentication checks on media objects
# and return a hash to be used as JSON in a controller response
class MediaAuthenticationJSON
  def initialize(opts = {})
    @user = opts[:user]
    @media = opts[:media]
    @auth_url = opts[:auth_url]
  end

  def as_json(*)
    return location_only_restricted_json if only_location_grants_access?
    return stanford_only_restricted_json if only_stanford_grants_access?
    return stanford_or_location_restricted_json if stanford_or_location_grants_access?
    {}
  end

  private

  attr_reader :auth_url, :media, :user

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

  def only_location_grants_access?
    location_grants_access? && !stanford_grants_access?
  end

  def only_stanford_grants_access?
    stanford_grants_access? && !location_restricted?
  end

  def stanford_or_location_grants_access?
    stanford_grants_access? && location_grants_access?
  end

  def stanford_restricted?
    Array.wrap(media.stanford_only_rights)[0]
  end

  def location_restricted?
    media.restricted_by_location?
  end

  def user_is_in_location?
    Array.wrap(media.location_rights(user.location))[0]
  end

  def stanford_grants_access?
    stanford_restricted? && !user.webauth_user
  end

  def location_grants_access?
    location_restricted? && !user_is_in_location?
  end
end
