##
# Simple user model for anonymous, webauth, and locally authenticated "app" users
class User
  include ActiveModel::Model

  attr_accessor :id, :webauth_user, :app_user, :ldap_groups

  def webauth_user?
    webauth_user
  end

  def stanford?
    webauth_user? && (ldap_groups & Settings.user.stanford_groups).any?
  end

  def app_user?
    app_user
  end

  def etag
    id
  end
end
