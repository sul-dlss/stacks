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

  def location
    ApprovedLocation.new(self).to_s
  end

  def self.from_token(token, _options = {})
    attributes, timestamp = encryptor.decrypt_and_verify(token)

    User.new(attributes.merge(token_user: true)) if timestamp >= 1.hour.ago
  end

  def token
    self.class.encryptor.encrypt_and_sign([{ id: id, ldap_groups: ldap_groups }, Time.zone.now])
  end

  def self.encryptor
    ActiveSupport::MessageEncryptor.new(Rails.application.secrets.secret_key_base)
  end
end
