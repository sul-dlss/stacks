# frozen_string_literal: true

# Represents a remote Iiif endpoint
class IiifImage < SourceImage
  include ActiveSupport::Benchmarkable
  # @params id [StacksIdentifier]
  # @params transformation [IIIF::Image::Transformation]
  # @params base_uri [String]
  def initialize(id:, transformation:, base_uri:)
    @id = id
    @transformation = transformation
    @base_uri = base_uri
  end

  delegate :valid?, to: :image_uri

  private

  def image_uri
    @image_uri ||= IIIF::Image::URI.new(base_uri: @base_uri, identifier: remote_id, transformation: transformation)
  end

  def image_url
    image_uri.to_s
  end

  def remote_id
    RemoteIiifIdentifier.convert(id)
  end
end
