# frozen_string_literal: true

##
# API for delivering files from stacks
class FileController < ApplicationController
  rescue_from ActionController::MissingFile do
    render plain: 'File not found', status: :not_found
  end

  def show
    return unless stale?(**cache_headers)

    authorize! :read, current_file
    expires_in 10.minutes
    response.headers['Accept-Ranges'] = 'bytes'
    response.headers['Content-Length'] = current_file.content_length

    send_file current_file.path, disposition: disposition
  end

  def options
    response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Range'
    response.headers['Access-Control-Max-Age'] = 1.day.to_i

    head :ok
  end

  private

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
      public: anonymous_ability.can?(:read, current_file),
      template: false
    }
  end

  def current_file
    @file ||= StacksFile.new(file_params)
  end
end
