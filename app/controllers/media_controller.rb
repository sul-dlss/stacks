# frozen_string_literal: true

##
# API for delivering streaming media via stacks
class MediaController < ApplicationController
  skip_forgery_protection

  before_action :load_media

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

  def allowed_params
    params.permit(:action, :callback, :id, :file_name, :format, :stacks_token, :user_ip)
  end

  def hash_for_auth_check
    if can? :stream, current_media
      # we use IP from which request originated -- we want the end user IP, not
      #   a service on the user's behalf (load-balancer, etc.)
      token = URI.encode_www_form_component(current_media.encrypted_token(ip: request.remote_ip))
      {
        status: :success,
        token:,
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

  def id
    allowed_params[:id]
  end

  def file_name
    allowed_params[:file_name]
  end

  def load_media
    @media ||= StacksMediaStream.new(stacks_file:)
  end

  def stacks_file
    StacksFile.new(file_name: params[:file_name], cocina: Cocina.find(params[:id]))
  end

  def current_media
    @media
  end

  def token_valid?(token, expected_id, expected_file_name, expected_user_ip)
    StacksMediaToken.verify_encrypted_token? token, expected_id, expected_file_name, expected_user_ip
  end
end
