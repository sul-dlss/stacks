# frozen_string_literal: true

##
# Represents a file on disk in stacks. A StacksFile may be downloaded and
# may be the file that backs a StacksImage or StacksMediaStream
class StacksFile
  class NotFound < StandardError; end

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
  delegate :content_length, to: :s3_head

  def client_params
    { bucket: Settings.s3.bucket, key: s3_key }
  end

  # How many times to ask S3 for the rest of the file after it drops the connection
  S3_RESUME_LIMIT = 3

  # Yields the bytes of the file (or of a RangeHeader::Range of it) from S3 in chunks.
  # If S3 drops the connection partway through, ask again for the bytes we haven't yielded.
  # The S3 client won't retry a ranged request that streams to a block, and by then we've
  # promised the client a content-length, so giving up would leave them a truncated response.
  def s3_object(range: RangeHeader::Range.new(0, content_length - 1))
    return if range.content_length <= 0

    yielded = 0
    resumes = 0
    begin
      in_block = false
      get_s3_range(range_start: range.range_start + yielded, range_end: range.range_end) do |chunk|
        in_block = true
        yield chunk
        in_block = false
        yielded += chunk.bytesize
      end
    rescue Seahorse::Client::NetworkingError
      # The S3 client wraps errors from the block too, but those come from writing to our client.
      raise if in_block || resumes >= S3_RESUME_LIMIT

      resumes += 1
      retry
    end
  end

  # @raises Aws::S3::Errors::NotFound
  def mtime
    @mtime ||= s3_head.last_modified
  end

  def etag
    mtime&.to_i
  end

  def content_type
    cocina_file['hasMimeType']
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

    "weka/#{File.dirname(file_path)}/#{streaming_url_file_segment}"
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

  private

  def get_s3_range(range_start:, range_end:, &)
    S3ClientFactory.create_client.get_object(client_params.merge(range: "bytes=#{range_start}-#{range_end}"), &)
  rescue Aws::S3::Errors::NoSuchKey
    raise "Unable to find file at #{s3_key}"
  end

  def s3_head
    @s3_head ||= S3ClientFactory.create_client.head_object(bucket: Settings.s3.bucket, key: s3_key)
  rescue Aws::S3::Errors::NotFound
    raise NotFound, "Unable to find file at #{s3_key}"
  end

  def cocina_file
    @cocina_file ||= cocina.find_file(file_name)
  end

  def s3_key
    @s3_key ||= storage_root.relative_path
  end

  def storage_root
    @storage_root ||= StorageRoot.new(cocina:, file_name:)
  end
end
