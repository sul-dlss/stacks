# frozen_string_literal: true

##
# media stream via stacks
class StacksMediaStream
  extend ActiveSupport::Concern
  include StacksRights
  include ActiveModel::Model

  # @return [StacksFile] the file on disk that back this projection
  def file
    @file ||= StacksFile.new
  end

  delegate :id, :id=, :etag, :mtime, to: :file
  attr_accessor :format
end
