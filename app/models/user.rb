##
# Simple user model for anonymous, webauth, and locally authenticated "app" users
class User < ApplicationRecord
  include ActiveSupport::Callbacks

  define_callbacks :groups_changed

  set_callback :groups_changed, :after, :create_roles_from_workgroups

  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :remote_user_authenticatable, :registerable,
         :recoverable, :rememberable

  rolify

  after_create :create_roles_from_workgroups

  attr_accessor :id, :webauth_user, :anonymous_locatable_user, :app_user, :token_user, :ldap_groups, :ip_address

  def webauth_user?
    webauth_user || persisted?
  end

  def anonymous_locatable_user?
    anonymous_locatable_user
  end

  def stanford?
    (ldap_groups.present? && (ldap_groups & Settings.user.stanford_groups).any?) || has_role?(:stanford)
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

  def location?
    location.present?
  end

  def self.from_token(token, additional_attributes = {})
    attributes, timestamp = encryptor.decrypt_and_verify(token)

    User.new(attributes.merge(token_user: true).merge(additional_attributes)) if timestamp >= 1.hour.ago
  end

  def token
    self.class.encryptor.encrypt_and_sign([
                                            {
                                              id: id,
                                              email: email,
                                              ldap_groups: ldap_groups,
                                              ip_address: ip_address,
                                              webauth_user: webauth_user
                                            },
                                            Time.zone.now
                                          ])
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

  def shibboleth_groups=(groups)
    self.ldap_groups = groups.split(';')
  end

  def webauth_groups=(groups)
    self.ldap_groups = groups.split('|')
  end

  def ldap_groups=(group)
    run_callbacks :groups_changed do
      @ldap_groups = group
    end
  end

  def create_roles_from_workgroups
    add_role(:stanford) if ldap_groups.present? && (ldap_groups & Settings.user.stanford_groups).any?
  end
end
