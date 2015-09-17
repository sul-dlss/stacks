class ApplicationController < ActionController::Base
  include Squash::Ruby::ControllerMethods
  enable_squash_client

  include ActionController::HttpAuthentication::Basic

  rescue_from CanCan::AccessDenied, with: :rescue_can_can

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
    User.new(id: request.remote_user,
             webauth_user: true,
             ldap_groups: request.env.fetch('WEBAUTH_LDAPPRIVGROUP', '').split('|'))
  end

  def rescue_can_can(exception)
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"

    render file: "#{Rails.root}/public/403.html", status: 403, layout: false
  end

  # stubs for squash
  def flash
    {}
  end

  def cookies
    {}
  end
end
