##
# API for delivering streaming media via stacks
class MediaController < ApplicationController
  before_action :load_media
  before_action :set_origin_header, except: [:auth_check]
  before_action :set_cors_headers, only: [:auth_check]

  rescue_from ActionController::MissingFile do
    render text: 'File not found', status: :not_found
  end

  def verify_token
    # the media service calling verify_token provides the end-user IP address,
    # as we care about the (user) IP address that made a request to the media service with the
    # stacks_token, not the IP address of the service checking the stacks_token.
    if token_valid? allowed_params[:stacks_token], id, file_name, allowed_params[:user_ip]
      render text: 'valid token', status: :ok
    else
      render text: 'invalid token', status: :forbidden
    end
  end

  # jsonp response
  def auth_check
    respond_to do |format|
      format.js { render json: hash_for_auth_check, callback: allowed_params[:callback] }
    end
  end

  private

  # We do not rely on the web server to set Access-Control-Allow-Origin for *any* /media request,
  # so we set it manually ourselves.
  def set_origin_header
    response.headers['Access-Control-Allow-Origin'] = '*'
  end

  def set_cors_headers
    response.headers['Access-Control-Allow-Origin'] = Settings.cors.allow_origin_url
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  def allowed_params
    params.permit(:action, :callback, :id, :file_name, :format, :stacks_token, :user_ip)
  end

  def hash_for_auth_check
    if can? :stream, current_media
      { status: :success, token: encrypted_token }
    else
      MediaAuthenticationJSON.new(
        user: current_user,
        media: current_media,
        auth_url: iiif_auth_api_url
      )
    end
  end

  def stacks_media_stream_params
    allowed_params.slice(:id, :file_name, :format)
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
