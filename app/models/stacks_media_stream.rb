# frozen_string_literal: true

##
# media stream via stacks
class StacksMediaStream
  include ActiveModel::Model
  include StacksRights

  # @return [StacksFile] the file on disk that back this projection
  def file
    @file ||= StacksFile.new
  end

  attr_accessor :format, :id, :file_name
  delegate :id, :id=, :file_name, :file_name=, :etag, :mtime, to: :file
end
