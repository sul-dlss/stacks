# frozen_string_literal: true

##
# API for delivering files from stacks
class FileController < ApplicationController
  rescue_from ActionController::MissingFile do
    render plain: 'File not found', status: :not_found
  end

  def show
    return unless stale?(cache_headers)

    authorize! :read, current_file
    expires_in 10.minutes
    response.headers['Accept-Ranges'] = 'bytes'
    response.headers['Content-Length'] = current_file.content_length

    send_file current_file.path, disposition: disposition
  end

  private

  def disposition
    return :attachment if allowed_params[:download]

    :inline
  end

  def allowed_params
    params.permit(:id, :file_name, :download)
  end

  def stacks_file_params
    allowed_params.slice(:download)
                  .merge(id: stacks_identifier)
  end

  def stacks_identifier
    id = StacksIdentifier.new(druid: params[:id],
                              file_name: params[:file_name])
    return id if id.valid?

    raise ActionController::RoutingError, 'Invalid druid'
  end

  # called when CanCan::AccessDenied error is raised, typically by authorize!
  #   Should only be here if
  #   a)  access not allowed (send to super)  OR
  #   b)  need user to login to determine if access allowed
  def rescue_can_can(exception)
    stanford_restricted, _rule = current_file.stanford_only_rights
    if stanford_restricted && !current_user.webauth_user?
      redirect_to auth_file_url(allowed_params.to_h.symbolize_keys)
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
    @file ||= StacksFile.new(stacks_file_params)
  end
end
