# frozen_string_literal: true

##
# media stream via stacks
class StacksMediaStream
  include ActiveModel::Model

  # @return [StacksFile] the file on disk that back this projection
  def file
    @file ||= StacksFile.new(id: id, file_name: file_name)
  end

  attr_accessor :format, :id, :file_name
  delegate :etag, :mtime, to: :file

  def stacks_rights
    @stacks_rights ||= StacksRights.new(id: id, file_name: file_name)
  end
  delegate :rights, :restricted_by_location?, :stanford_restricted?, to: :stacks_rights
end
