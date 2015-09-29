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

  def rescue_can_can
    if current_user
      super
    else
      redirect_to auth_file_url(params.symbolize_keys)
    end
  end

  def file_params
    params.slice(:id, :file_name)
  end

  def cache_headers
    {
      etag: @file.etag,
      last_modified: @file.mtime,
      public: anonymous_ability.can?(:read, @file),
      template: false
    }
  end

  def load_file
    @file ||= StacksFile.new(file_params)
  end
end
