# frozen_string_literal: true

# :nodoc:
class ApplicationController < ActionController::Base
  include CurrentUserConcern

  rescue_from CanCan::AccessDenied, with: :rescue_can_can
  rescue_from Purl::Exception do
    head :not_found
  end
  before_action :set_origin_header

  protect_from_forgery with: :null_session

  private

  def set_origin_header
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  def rescue_can_can(exception)
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"

    render file: "#{Rails.root}/public/403.html", status: :forbidden, layout: false
  end
end
