class User
  include ActiveModel::Model

  attr_accessor :id, :webauth_user


  def webauth_user?
    !!webauth_user
  end
end