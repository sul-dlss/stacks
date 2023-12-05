# frozen_string_literal: true

##
# API for delivering streaming media via stacks
class MediaController < ApplicationController
  include AuthConcern

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

  private

  def stacks_media_stream_params
    allowed_params.slice(:format, :id, :file_name)
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

  def current_file
    @media
  end

  def allowed?
    can? :stream, current_file
  end

  def valid_response
    super.merge(token: URI.encode_www_form_component(encrypted_token))
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
