class FileController < ApplicationController
  before_action :load_file

  def show
    fail "File Not Found" unless @file.exist?
    return unless stale?(cache_headers)
    expires_in 10.minutes
    authorize! :read, @file
    send_file @file.path, x_sendfile: true
  end

  private

  def cache_headers
    {
      etag: @file.etag,
      last_modified: @file.mtime,
      public: anonymous_ability.can?(:read, @file),
      template: false
    }
  end

  def load_file
    @file ||= StacksFile.new(params)
  end
end
