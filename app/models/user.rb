class User
  include ActiveModel::Model

  attr_accessor :id, :webauth_user, :app_user

  def webauth_user?
    !!webauth_user
  end

  def app_user?
    !!app_user
  end
end