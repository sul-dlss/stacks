# frozen_string_literal: true

##
# Represents a file on disk in stacks. A StacksFile may be downloaded and
# may be the file that backs a StacksImage or StacksMediaStream
# rubocop:disable Metrics/ClassLength
class StacksFile
  class NotFound < StandardError; end

  include ActiveModel::Validations

  STREAMING_RETRY_LIMIT = 3

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

  def client_params
    { bucket: Settings.s3.bucket, key: s3_key }
  end

  def s3_object(&)
    stream_from_s3(client_params, &)
  rescue Aws::S3::Errors::NoSuchKey
    raise "Unable to find file at #{s3_key}"
  end

  def s3_range(range: nil, &)
    params = client_params.merge(range: range)

    stream_from_s3(params, &)
  rescue Aws::S3::Errors::NoSuchKey
    raise "Unable to find file at #{s3_key}"
  end

  # @raises Aws::S3::Errors::NotFound
  def mtime
    @mtime ||= s3_head.last_modified
  end

  def etag
    mtime&.to_i
  end

  def content_length
    cocina_file['size']
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

  def stream_from_s3(params)
    bytes_streamed = 0
    retries = 0
    initial_range = params[:range]

    begin
      S3ClientFactory.create_client.get_object(params) do |chunk|
        yield chunk
        bytes_streamed += chunk.bytesize
      end
    rescue Aws::S3::Plugins::NonRetryableStreamingError, Seahorse::Client::NetworkingError => e
      raise unless retryable_streaming_error?(e)

      retries += 1
      raise if retries > STREAMING_RETRY_LIMIT

      params = params.merge(range: resumed_range(initial_range, bytes_streamed))
      retry
    end
  end

  def retryable_streaming_error?(error)
    error.is_a?(Seahorse::Client::NetworkingError) ||
      error.original_error.is_a?(Seahorse::Client::NetworkingError)
  end

  def resumed_range(range, bytes_streamed)
    range_start, range_end = range&.delete_prefix('bytes=')&.split('-', 2)
    range_start = range_start.to_i + bytes_streamed
    "bytes=#{range_start}-#{range_end}"
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
# rubocop:enable Metrics/ClassLength
