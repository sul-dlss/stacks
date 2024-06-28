# frozen_string_literal: true

##
# media stream via stacks
class StacksMediaStream
  # @param [StacksFile] stacks_file the file on disk that back this stream
  def initialize(stacks_file:)
    @stacks_file = stacks_file
  end
  attr_accessor :stacks_file

  delegate :etag, :mtime, :stacks_rights, to: :stacks_file

  delegate :rights, :restricted_by_location?, :stanford_restricted?, :embargoed?,
           :embargo_release_date, :location, to: :stacks_rights
end
