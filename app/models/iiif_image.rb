# frozen_string_literal: true

# Represents a remote Iiif endpoint
class IiifImage
  include ActiveSupport::Benchmarkable
  # @params id [String]
  # @params file_name [String]
  # @params transformation [IIIF::Image::Transformation]
  # @params base_uri [String]
  def initialize(id:, file_name:, transformation:, base_uri: Settings.imageserver.base_uri)
    @id = id
    @file_name = file_name
    @transformation = transformation
    @base_uri = base_uri
  end

  delegate :valid?, to: :image_uri

  # Get the image data from the remote server
  # @return [IO]
  def response
    with_retries max_tries: 3, rescue: [HTTP::ConnectionError] do
      benchmark "Fetch #{image_url}" do
        HTTP.use({ normalize_uri: { normalizer: lambda(&:itself) } }).get(image_url)
      end
    end
  end

  private

  def image_uri
    @image_uri ||= IIIF::Image::URI.new(base_uri: @base_uri, identifier: remote_id, transformation: transformation)
  end

  def image_url
    image_uri.to_s
  end

  def remote_id
    CGI.escape(StacksFile.new(id: id, file_name: file_name).treeified_path)
  end

  attr_reader :transformation, :id, :file_name

  delegate :logger, to: Rails
end
