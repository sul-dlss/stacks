# frozen_string_literal: true

##
# Represents a file on disk in stacks. A StacksFile may be downloaded and
# may be the file that backs a StacksImage or StacksMediaStream
class StacksFile
  include ActiveModel::Model
  include ActiveModel::Validations

  attr_accessor :id, :file_name, :current_ability, :download

  validates :id, format: { with: StorageRoot::DRUID_PARTS_PATTERN }

  # Some files exist but have unreadable permissions, treat these as non-existent
  def readable?
    path && File.world_readable?(path)
  end

  def mtime
    @mtime ||= File.mtime(path) if readable?
  end

  def etag
    mtime&.to_i
  end

  def content_length
    @content_length ||= File.size(path) if readable?
  end

  def path
    @path ||= storage_root.absolute_path
  end

  def treeified_path
    storage_root.relative_path
  end

  def storage_root
    @storage_root ||= StorageRoot.new(druid: id, file_name:)
  end

  def stacks_rights
    @stacks_rights ||= StacksRights.new(id:, file_name:)
  end
  delegate :rights, :cocina_rights, :restricted_by_location?, :stanford_restricted?, :embargoed?,
           :embargo_release_date, :location, to: :stacks_rights

  def streamable?
    accepted_formats = [".mov", ".mp4", ".mpeg", ".m4a", ".mp3"]
    accepted_formats.include? File.extname(file_name)
  end

  def streaming_url
    "#{Settings.stream.url}/#{storage_root.treeified_id}/#{streaming_url_file_segment}/playlist.m3u8"
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
