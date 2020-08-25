module CurrentUserConcern
  include ActionController::HttpAuthentication::Basic
  include ActionController::HttpAuthentication::Token

  def current_user
    @current_user ||= if has_basic_credentials?(request)
                        basic_auth_user
                      elsif has_bearer_credentials?(request)
                        bearer_auth_user
                      elsif has_bearer_cookie?
                        bearer_cookie_user
                      elsif session[:remote_user] || request.remote_user.present?
                        webauth_user
                      else
                        anonymous_locatable_user
                      end
  end

  def anonymous_ability
    @anonymous_ability ||= Ability.new(anonymous_locatable_user)
  end

  private

  def basic_auth_user
    user_name, password = user_name_and_password(request)
    credentials = Settings.app_users[user_name]

    User.new(id: user_name, app_user: true) if credentials && credentials == password
  end

  def bearer_auth_user
    token, _options = token_and_options(request)
    token_user(token)
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

  def webauth_user
    ldap_groups = session[:workgroups].split(';') if session[:workgroups].present?
    ldap_groups ||= workgroups_from_env

    User.new(id: session[:remote_user] || request.remote_user,
             ip_address: request.remote_ip,
             webauth_user: true,
             ldap_groups: ldap_groups)
  end

  def anonymous_locatable_user
    User.new(ip_address: request.remote_ip,
             anonymous_locatable_user: true)
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

  def workgroups_from_env
    request.env.fetch('eduPersonEntitlement', '').split(';')
  end
end
