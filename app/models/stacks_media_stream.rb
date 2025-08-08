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
    file_path = "#{stacks_file.storage_root.treeified_id.delete_prefix('/')}/#{streaming_url_file_segment}"
    WowzaSecureToken.new(file_path:).streaming_url
  end

  private

  def streaming_url_file_segment
    case File.extname(file_name)
    when '.mp3'
      "mp3:#{file_name}"
    else
      "mp4:#{file_name}"
    end
  end
end
