# frozen_string_literal: true

##
# Simple user model for anonymous, webauth, and locally authenticated "app" users
class User
  include ActiveModel::Model

  attr_accessor :id, :webauth_user, :anonymous_locatable_user, :app_user, :token_user, :ldap_groups, :ip_address

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

  def self.from_token(token, additional_attributes = {})
    attributes, timestamp = encryptor.decrypt_and_verify(token)

    User.new(attributes.merge(token_user: true).merge(additional_attributes)) if timestamp >= 1.hour.ago
  end

  def token
    self.class.encryptor.encrypt_and_sign([{ id: id, ldap_groups: ldap_groups, ip_address: ip_address }, Time.zone.now])
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
