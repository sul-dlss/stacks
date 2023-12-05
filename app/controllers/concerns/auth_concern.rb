# frozen_string_literal: true

# Methods associated with performing authorization checks
module AuthConcern
  extend ActiveSupport::Concern

  included do
    before_action :set_cors_headers, only: [:auth_check]
  end

  # jsonp response
  def auth_check
    # IE 11 and Edge on Windows 10 doesn't request the correct format. So just hardcode
    # JSON as the return format since that's what we always do.
    render json: hash_for_auth_check, callback: allowed_params[:callback]
  end

  private

  def allowed_params
    params.permit(:action, :callback, :id, :file_name, :format, :stacks_token, :user_ip)
  end

  # In order for media authentication to work, the wowza server must have
  # Access-Control-Allow-Credentials header set (which is set by default when CORS is enabled in wowza),
  # which means that Access-Control-Allow-Origin cannot be set to * (wowza default) and instead
  # needs to specify a host (e.g. the embed server of choice, presumably used in purl with
  # particular stacks). This means that only the specified host will be granted credentialed requests.
  def set_cors_headers
    response.headers['Access-Control-Allow-Origin'] = Settings.cors.allow_origin_url
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  def hash_for_auth_check
    if allowed?
      valid_response
    else
      AuthenticationJson.new(
        user: current_user,
        ability: current_ability,
        file: current_file,
        auth_url: iiif_auth_api_url
      )
    end
  end

  def valid_response
    {
      status: :success,
      access_restrictions: {
        stanford_restricted: current_file.stanford_restricted?,
        restricted_by_location: current_file.restricted_by_location?,
        embargoed: current_file.embargoed?,
        embargo_release_date: current_file.embargo_release_date
      }
    }
  end
end
