# Common methods for projections (StacksImage, StacksMediaStream) that
# are backed by a file on disk.
module BackedByFile
  extend ActiveSupport::Concern
  include StacksRights
  include ActiveModel::Model

  # @return [StacksFile] the file on dis that back this projection
  def file
    @file ||= StacksFile.new
  end

  delegate :id, :id=, :file_name, :file_name=, :etag, :druid, :mtime,
           :current_ability, :current_ability=, to: :file
end
