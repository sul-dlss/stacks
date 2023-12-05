# frozen_string_literal: true

##
# API for delivering files from stacks
class FileController < ApplicationController
  before_action :set_cors_headers, only: [:auth_check]

  rescue_from ActionController::MissingFile do
    render plain: 'File not found', status: :not_found
  end

  def show
    return unless stale?(**cache_headers)

    authorize! :download, current_file
    expires_in 10.minutes
    response.headers['Accept-Ranges'] = 'bytes'
    response.headers['Content-Length'] = current_file.content_length
    response.headers.delete('X-Frame-Options')

    send_file current_file.path, disposition:
  end

  def options
    response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Range'
    response.headers['Access-Control-Max-Age'] = 1.day.to_i

    head :ok
  end

  # jsonp response
  def auth_check
    # IE 11 and Edge on Windows 10 doesn't request the correct format. So just hardcode
    # JSON as the return format since that's what we always do.
    render json: hash_for_auth_check, callback: allowed_params[:callback]
  end

  private

  def set_cors_headers
    response.headers['Access-Control-Allow-Origin'] = Settings.cors.allow_origin_url
    response.headers['Access-Control-Allow-Credentials'] = 'true'
  end

  def allowed_params
    params.permit(:action, :callback, :id, :file_name, :format)
  end

  def hash_for_auth_check
    if can? :access, current_file
      {
        status: :success,
        access_restrictions: {
          stanford_restricted: current_file.stanford_restricted?,
          restricted_by_location: current_file.restricted_by_location?,
          embargoed: current_file.embargoed?,
          embargo_release_date: current_file.embargo_release_date
        }
      }
    else
      AuthenticationJson.new(
        user: current_user,
        ability: current_ability,
        file: current_file,
        auth_url: iiif_auth_api_url
      )
    end
  end

  def disposition
    return :attachment if file_params[:download]

    :inline
  end

  def file_params
    params.permit(:id, :file_name, :download)
  end

  # called when CanCan::AccessDenied error is raised, typically by authorize!
  #   Should only be here if
  #   a)  access not allowed (send to super)  OR
  #   b)  need user to login to determine if access allowed
  def rescue_can_can(exception)
    if User.stanford_generic_user.ability.can?(:access, current_file) && !current_user.webauth_user?
      redirect_to auth_file_url(file_params.to_h.symbolize_keys)
    else
      super
    end
  end

  def cache_headers
    {
      etag: [current_file.etag, current_user.try(:etag)],
      last_modified: current_file.mtime,
      public: anonymous_ability.can?(:download, current_file),
      template: false
    }
  end

  def current_file
    @file ||= StacksFile.new(file_params)
  end
end
