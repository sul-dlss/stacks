# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  allow_browser versions: :modern
  include CurrentUserConcern

  rescue_from CanCan::AccessDenied, with: :rescue_can_can
  rescue_from Purl::Exception do
    head :not_found
  end
  before_action :set_cors_headers

  protect_from_forgery with: :null_session

  private

  def set_cors_headers
    origin = request.origin
    permitted_origins = [Settings.cors.allow_origin_url]
    if permitted_origins.include?(origin)
      response.headers['Access-Control-Allow-Origin'] = origin
      response.headers['Access-Control-Allow-Credentials'] = true
    else
      response.headers['Access-Control-Allow-Origin'] = '*'
    end
  end

  def rescue_can_can(exception)
    Rails.logger.debug { "Access denied on #{exception.action} #{exception.subject.inspect}" }

    render file: "#{Rails.root}/public/403.html", status: :forbidden, layout: false
  end

  # Overriding CanCan::ControllerAdditions
  def current_ability
    @current_ability ||= ability_class.new(current_user)
  end

  def ability_class
    CocinaAbility
  end
end
