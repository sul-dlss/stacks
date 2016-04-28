##
# API for delivering files from stacks
class FileController < ApplicationController
  before_action :load_file

  rescue_from ActionController::MissingFile do
    render text: 'File not found', status: :not_found
  end

  def show
    return unless stale?(cache_headers)
    authorize! :read, @file
    expires_in 10.minutes

    send_file @file.path
  end

  private

  def allowed_params
    params.permit(:id, :file_name)
  end
  # the args needed for StacksFile.new happen to be the same as allowed_params
  alias stacks_file_params allowed_params

  def rescue_can_can(exception)
    if current_user
      super(exception)
    else
      redirect_to auth_file_url(allowed_params.symbolize_keys)
    end
  end

  def cache_headers
    {
      etag: [@file.etag, current_user.try(:etag)],
      last_modified: @file.mtime,
      public: anonymous_ability.can?(:read, @file),
      template: false
    }
  end

  def load_file
    @file ||= StacksFile.new(stacks_file_params)
  end
end
