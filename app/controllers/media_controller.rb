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

  private

  def allowed_params
    params.permit(:action, :id, :file_name, :format)
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

  def load_media
    @media ||= StacksMediaStream.new(stacks_media_stream_params)
  end
end
