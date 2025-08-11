# frozen_string_literal: true

##
# Represents a file on disk in stacks. A StacksFile may be downloaded and
# may be the file that backs a StacksImage or StacksMediaStream
class StacksFile
  include ActiveModel::Validations

  def initialize(file_name:, cocina:)
    @file_name = file_name
    @cocina = cocina
    validate!
  end

  attr_reader :file_name, :cocina

  def id
    cocina.druid
  end

  validates :file_name, presence: true

  delegate :not_proxied?, to: :cocina

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

  # Used as the IIIF identifier for retrieving this file from the image server
  # return the content addressable path if available, otherwise the legacy path
  def cantaloupe_identifier
    CGI.escape(storage_root.relative_path)
  end

  def wowza_identifier
    file_path = storage_root.relative_path
    streaming_url_file_segment = case File.extname(file_name)
                                 when '.mp3'
                                   "mp3:#{File.basename(file_path)}"
                                 else
                                   "mp4:#{File.basename(file_path)}"
                                 end

    "#{File.dirname(file_path)}/#{streaming_url_file_segment}"
  end

  def storage_root
    @storage_root ||= StorageRoot.new(cocina:, file_name:)
  end

  def stacks_rights
    @stacks_rights ||= StacksRights.new(cocina:, file_name:)
  end

  delegate :rights, :restricted_by_location?, :stanford_restricted?, :embargoed?,
           :embargo_release_date, :location, :no_download?, :world_viewable?, to: :stacks_rights

  def streamable?
    accepted_formats = [".mov", ".mp4", ".mpeg", ".m4a", ".mp3"]
    accepted_formats.include? File.extname(file_name)
  end
end
