# frozen_string_literal: true

##
# media stream via stacks
class StacksMediaStream
  # @param [StacksFile] stacks_file the file on disk that back this stream
  def initialize(stacks_file:)
    @stacks_file = stacks_file
  end
  attr_accessor :stacks_file

  delegate :id, :file_name, :etag, :mtime, :stacks_rights, :not_proxied?, to: :stacks_file

  delegate :rights, :restricted_by_location?, :stanford_restricted?, :embargoed?,
           :embargo_release_date, :location, :world_viewable?, :no_download?, to: :stacks_rights

  def streaming_url
    WowzaSecureToken.new(file_path: stacks_file.wowza_identifier).streaming_url
  end
end
