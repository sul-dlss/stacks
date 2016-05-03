##
# API for delivering streaming media via stacks
class MediaController < ApplicationController
  before_action :load_media

  rescue_from ActionController::MissingFile do
    render text: 'File not found', status: :not_found
  end

  def download
    authorize! :download, @media
    expires_in 10.minutes

    self.content_type = Mime::Type.lookup_by_extension(allowed_params[:format]).to_s
    send_file @media.path
  end

  def stream
    authorize! :read, @media
    respond_to do |format|
      format.m3u8 do
        redirect_to @media.to_playlist_url
      end
      format.mpd do
        redirect_to @media.to_manifest_url
      end
    end
  end

  def verify_token
    # get the IP address from a parameter.  the service that's calling verify_token will pass it along,
    # because we care about the IP address that made a request to that service with the token, not the IP
    # address of the service checking the token.
    if token_valid? allowed_params[:token_string], id, file_name, allowed_params[:user_ip_addr]
      render text: 'valid token', status: :ok
    else
      render text: 'invalid token', status: :forbidden
    end
  end

  private

  def allowed_params
    params.permit(:action, :id, :file_name, :format, :token_string, :user_ip_addr)
  end

  def rescue_can_can(exception)
    if current_user
      super(exception)
    elsif allowed_params['action'] == 'stream'
      redirect_to auth_media_stream_url(allowed_params.symbolize_keys)
    else
      redirect_to auth_media_download_url(allowed_params.symbolize_keys)
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

  def token_valid?(token_string, expected_id, expected_file_name, expected_user_ip_addr)
    StacksMediaToken.verify_encrypted_token? token_string, expected_id, expected_file_name, expected_user_ip_addr
  end
end
