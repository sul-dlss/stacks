# frozen_string_literal: true

##
# API for delivering streaming media via stacks
class MediaController < ApplicationController
  skip_forgery_protection

  before_action :load_media
  before_action :set_cors_headers, only: [:auth_check]

  rescue_from ActionController::MissingFile do
    render plain: 'File not found', status: :not_found
  end

  def verify_token
    # the media service calling verify_token provides the end-user IP address,
    # as we care about the (user) IP address that made a request to the media service with the
    # stacks_token, not the IP address of the service checking the stacks_token.
    if token_valid? allowed_params[:stacks_token], id, file_name, allowed_params[:user_ip]
      render plain: 'valid token', status: :ok
    else
      render plain: 'invalid token', status: :forbidden
    end
  end

  # jsonp response
  def auth_check
    # IE 11 and Edge on Windows 10 doesn't request the correct format. So just hardcode
    # JSON as the return format since that's what we always do.
    render json: hash_for_auth_check, callback: allowed_params[:callback]
  end

  private

  # In order for media authentication to work, the wowza server must have
  # Access-Control-Allow-Credentials header set (which is set by default when CORS is enabled in wowza),
  # which means that Access-Control-Allow-Origin cannot be set to * (wowza default) and instead
  # needs to specify a host (e.g. the embed server of choice, presumably used in purl with
  # particular stacks). This means that only the specified host will be granted credentialed requests.
  def set_cors_headers
    response.headers['Access-Control-Allow-Origin'] = Settings.cors.allow_origin_url
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  def allowed_params
    params.permit(:action, :callback, :id, :file_name, :format, :stacks_token, :user_ip)
  end

  def hash_for_auth_check
    if can? :stream, current_media
      {
        status: :success,
        token: URI.encode_www_form_component(encrypted_token),
        access_restrictions: {
          stanford_restricted: current_media.stanford_restricted?,
          restricted_by_location: current_media.restricted_by_location?,
          embargoed: current_media.embargoed?,
          embargo_release_date: current_media.embargo_release_date
        }
      }
    else
      MediaAuthenticationJson.new(
        user: current_user,
        ability: current_ability,
        media: current_media,
        auth_url: iiif_auth_api_url
      )
    end
  end

  def stacks_media_stream_params
    allowed_params.slice(:id, :file_name)
  end

  def id
    allowed_params[:id]
  end

  def file_name
    allowed_params[:file_name]
  end

  def load_media
    @media ||= StacksMediaStream.new(stacks_media_stream_params)
  end

  def current_media
    @media
  end

  def token_valid?(token, expected_id, expected_file_name, expected_user_ip)
    StacksMediaToken.verify_encrypted_token? token, expected_id, expected_file_name, expected_user_ip
  end

  def encrypted_token
    # we use IP from which request originated -- we want the end user IP, not
    #   a service on the user's behalf (load-balancer, etc.)
    StacksMediaToken.new(id, file_name, request.remote_ip).to_encrypted_string
  end
end
