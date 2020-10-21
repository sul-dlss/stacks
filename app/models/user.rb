# frozen_string_literal: true

##
# Simple user model for anonymous, webauth, and locally authenticated "app" users
class User
  include ActiveModel::Model

  attr_accessor :id, :webauth_user, :anonymous_locatable_user, :app_user, :token_user,
                :ldap_groups, :ip_address, :jwt_tokens

  def ability
    Ability.new(self)
  end

  def webauth_user?
    webauth_user
  end

  def anonymous_locatable_user?
    anonymous_locatable_user
  end

  def stanford?
    ldap_groups.present? && (ldap_groups & Settings.user.stanford_groups).any?
  end

  def app_user?
    app_user
  end

  def token_user?
    token_user
  end

  def etag
    id
  end

  def locations
    @locations ||= ApprovedLocation.new(self).locations
  end

  def location?
    locations.any?
  end

  def append_jwt_token(token)
    self.jwt_tokens = (cdl_tokens.to_a + [decode_token(token)&.first])
                      .compact
                      .sort_by { |x| x.fetch(:iat, Time.zone.at(0)) }
                      .reverse
                      .uniq { |x| x[:aud] }
                      .pluck(:token)
  end

  def cdl_tokens
    return to_enum(:cdl_tokens) unless block_given?

    (jwt_tokens || []).each do |token|
      payload, _headers = decode_token(token)
      next unless payload && payload['sub'] == id && !token_expired?(payload)

      yield payload
    end
  end

  def decode_token(token)
    payload, headers = JWT.decode(token, Settings.cdl.jwt.secret, true, {
                                    algorithm: Settings.cdl.jwt.algorithm, sub: id, verify_sub: true
                                  })
    [payload&.merge(token: token)&.with_indifferent_access, headers]
  rescue JWT::ExpiredSignature, JWT::InvalidSubError
    nil
  end

  def token_expired?(payload)
    return true if payload['exp'] < Time.zone.now.to_i

    redis&.get("cdl.#{payload['jti']}") == 'expired'
  rescue Redis::BaseError => e
    Honeybadger.notify(e) if Rails.env.production?
    Rails.logger.error(e)

    false
  end

  def redis
    return unless Settings.cdl.redis.present? || ENV['REDIS_URL']

    @redis ||= Redis.new(Settings.cdl.redis.to_h)
  end

  def self.from_token(token, additional_attributes = {})
    attributes, timestamp, expiry = encryptor.decrypt_and_verify(token)
    expiry ||= timestamp + Settings.token.default_expiry_time

    return nil if expiry < Time.zone.now

    User.new(attributes.merge(token_user: true).merge(additional_attributes))
  end

  def token
    mint_time = Time.zone.now

    self.class.encryptor.encrypt_and_sign(
      [
        # stored parameters
        { id: id, ldap_groups: ldap_groups, ip_address: ip_address, jwt_tokens: jwt_tokens },
        # mint time
        mint_time,
        # expiry time
        mint_time + Settings.token.default_expiry_time
      ]
    )
  end

  def self.encryptor
    salt = 'user'
    key = ActiveSupport::KeyGenerator.new(Rails.application.secrets.secret_key_base).generate_key(salt, 32)
    ActiveSupport::MessageEncryptor.new(key)
  end

  def self.stanford_generic_user
    new(
      id: 'fake',
      webauth_user: true,
      ldap_groups: Settings.user.stanford_groups
    )
  end
end
