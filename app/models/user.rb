# frozen_string_literal: true

##
# Simple user model for anonymous, webauth, and locally authenticated "app" users
class User
  include ActiveModel::Model

  attr_accessor :id, :webauth_user, :anonymous_locatable_user, :token_user,
                :ldap_groups, :ip_address

  def ability
    ability_class.new(self)
  end

  def ability_class
    CocinaAbility
  end

  def webauth_user?
    webauth_user
  end

  def anonymous_locatable_user?
    anonymous_locatable_user
  end

  def stanford?
    ldap_groups.present? && ldap_groups.intersect?(Settings.user.stanford_groups)
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
        { id:, ldap_groups:, ip_address: },
        # mint time
        mint_time,
        # expiry time
        mint_time + Settings.token.default_expiry_time
      ]
    )
  end

  def self.encryptor
    salt = 'user'
    key = ActiveSupport::KeyGenerator.new(Rails.application.secret_key_base).generate_key(salt, 32)
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
