##
# API for delivering files from stacks
class FileController < ApplicationController
  before_action :load_file

  rescue_from ActionController::MissingFile do
    render plain: 'File not found', status: :not_found
  end

  def show
    return unless stale?(cache_headers)
    authorize! :read, current_file
    expires_in 10.minutes

    send_file current_file.path
  end

  private

  def allowed_params
    params.permit(:id, :file_name)
  end
  # the args needed for StacksFile.new happen to be the same as allowed_params
  alias stacks_file_params allowed_params

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
    @file
  end

  def load_file
    @file ||= StacksFile.new(stacks_file_params)
  end
end
