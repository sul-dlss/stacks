class ApplicationController < ActionController::Metal
  include AbstractController::Callbacks
  include ActionController::ConditionalGet
  include CanCan::ControllerAdditions

  include ActiveSupport::Rescuable
  include Squash::Ruby::ControllerMethods
  enable_squash_client

  include ActionController::HttpAuthentication::Basic

  protected

  def current_user
    @current_user ||= if has_basic_credentials?(request)
                        basic_auth_user
                      elsif request.remote_user
                        webauth_user
                      end
  end

  def anonymous_ability
    @anonymous_ability ||= Ability.new(nil)
  end

  def basic_auth_user
    user_name, password = user_name_and_password(request)
    credentials = Settings.app_users[user_name]

    User.new(id: user_name, app_user: true) if credentials && credentials == password
  end

  def webauth_user
    User.new(id: request.remote_user, webauth_user: true)
  end

  # stubs for squash
  def flash
    {}
  end

  def cookies
    {}
  end
end
