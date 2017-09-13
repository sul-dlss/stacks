# Common methods for projections (StacksImage, StacksMediaStream) that
# are backed by a file on disk.
module BackedByFile
  extend ActiveSupport::Concern
  include StacksRights
  include ActiveModel::Model

  # @return [StacksFile] the file on disk that back this projection
  def file
    @file ||= StacksFile.new
  end

  delegate :id, :id=, :file_name, :file_name=, :etag, :druid, :mtime,
           to: :file
end
