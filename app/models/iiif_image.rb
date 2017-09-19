# Represents a remote Iiif endpoint
class IiifImage < SourceImage
  include ActiveSupport::Benchmarkable
  # @params id [StacksIdentifier]
  # @params transformation [Iiif::Transformation]
  # @params base_uri [String]
  def initialize(id:, transformation:, base_uri:)
    @file = StacksFile.new(id: id)
    @transformation = transformation
    @base_uri = base_uri
  end

  def exist?
    Faraday.head(image_url)
  end

  delegate :valid?, to: :image_uri

  private

  attr_reader :transformation

  def image_uri
    @image_uri ||= Iiif::URI.new(base_uri: @base_uri, identifier: id, transformation: transformation)
  end

  def image_url
    image_uri.to_s
  end

  def id
    RemoteIiifIdentifier.convert(@file.id)
  end
end
