##
# API for delivering streaming media via stacks
class MediaController < ApplicationController
  before_action :load_media

  rescue_from ActionController::MissingFile do
    render text: 'File not found', status: :not_found
  end

  def download
    authorize! :download, current_media
    expires_in 10.minutes

    self.content_type = Mime::Type.lookup_by_extension(allowed_params[:format]).to_s
    send_file current_media.path
  end

  def stream
    authorize! :read, current_media # May raise CanCan::AccessDenied which is rescued by rescue_can_can
    respond_to do |format|
      format.m3u8 do
        redirect_to "#{current_media.to_playlist_url}?stacks_token=#{encrypted_token}"
      end
      format.mpd do
        redirect_to "#{current_media.to_manifest_url}?stacks_token=#{encrypted_token}"
      end
    end
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

  def allowed_params
    params.permit(:action, :callback, :id, :file_name, :format, :stacks_token, :user_ip)
  end

  # called when a CanCan::AccessDenied error is raised, typically by authorize!
  #   Should only be here if
  #   a)  access not allowed (send to super)  OR
  #   b)  need user to login to determine if access allowed
  def rescue_can_can(exception)
    stanford_restricted, _rule = current_media.stanford_only_rights
    return super unless stanford_restricted && !current_user.webauth_user?
    if allowed_params['action'] == 'stream'
      redirect_to auth_media_stream_url(allowed_params.symbolize_keys)
    else
      redirect_to auth_media_download_url(allowed_params.symbolize_keys)
    end
  end

  def hash_for_auth_check
    if can? :read, current_media
      { status: :success }
    else
      stanford_restricted, _rule = current_media.stanford_only_rights
      location_restricted = current_media.restricted_by_location?
      user_in_location, _rule = current_media.location_rights(current_user.location)
      could_authenticate = stanford_restricted && !current_user.webauth_user
      could_relocate = location_restricted && !user_in_location

      # TODO: ask Jessie if we should be following naming conventions or what for our keys
      if could_authenticate && could_relocate
        {
          status: [
            :stanford_restricted,
            :location_restricted
          ],
          service: {
            '@id' => iiif_auth_api_url,
            'label' => 'Stanford-affiliated? Login to play'
          },
          'label' => [
            'Limited access for non-Stanford guests.',
            'See Access conditions for more information.'
          ]
        }
      elsif could_authenticate && !location_restricted
        {
          # TODO: ask Jessie if this should/could be stanford_restricted
          status: :must_authenticate,
          service: {
            '@id' => iiif_auth_api_url,
            'label' => 'Stanford-affiliated? Login to play'
          }
        }
      elsif location_restricted && !user_in_location
        {
          status: :location_restricted,
          'label' => [
            'Restricted media cannot be played in your location.',
            'See Access conditions for more information.'
          ]
        }
      end
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
