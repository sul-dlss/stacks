# :nodoc:
class ApplicationController < ActionController::Base
  include ActionController::HttpAuthentication::Basic
  include ActionController::HttpAuthentication::Token

  rescue_from CanCan::AccessDenied, with: :rescue_can_can
  before_action :set_origin_header

  before_action do
    Rails.logger.info request.inspect
    Rails.logger.info current_user.inspect
  end

  def debug_auth
    respond_to do |format|
      format.json { render json: { current_user: current_user.as_json, request: request.as_json, host: ENV['HOSTNAME'] } }
    end
  end

  private

  def set_origin_header
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  def current_user
    @current_user ||= if has_basic_credentials?(request)
                        basic_auth_user
                      elsif has_bearer_credentials?(request)
                        bearer_auth_user
                      elsif has_bearer_cookie?
                        bearer_cookie_user
                      else
                        super || anonymous_locatable_user
                      end
  end

  def anonymous_ability
    @anonymous_ability ||= Ability.new(anonymous_locatable_user)
  end

  def stanford_generic_user
    @stanford_generic_user ||= User.stanford_generic_user
  end

  def basic_auth_user
    user_name, password = user_name_and_password(request)
    credentials = Settings.app_users[user_name]

    User.new(id: user_name, app_user: true) if credentials && credentials == password
  end

  def bearer_auth_user
    token, _options = token_and_options(request)
    token_user(token)
  end

  def bearer_cookie
    cookies[:bearer_token]
  end

  def has_bearer_cookie?
    bearer_cookie.present?
  end

  def has_bearer_credentials?(request)
    scheme = auth_scheme(request)
    request.authorization.present? && %w[Token Bearer].include?(scheme)
  end

  def bearer_cookie_user
    authorization_request = bearer_cookie.to_s
    params = token_params_from authorization_request
    token = params.shift[1]
    token_user(token)
  end

  def token_user(token)
    return unless token

    User.from_token(token, ip_address: request.remote_ip)
  end

  def anonymous_locatable_user
    User.new(ip_address: request.remote_ip,
             anonymous_locatable_user: true)
  end

  def rescue_can_can(exception)
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"

    render file: "#{Rails.root}/public/403.html", status: :forbidden, layout: false
  end

  def after_sign_out_path_for(*)
    '/Shibboleth.sso/Logout'
  end
end
