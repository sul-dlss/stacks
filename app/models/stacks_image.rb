# frozen_string_literal: true

##
# An image that can be delivered over the IIIF endpoint
class StacksImage
  include StacksRights
  include ActiveModel::Model

  # TODO: file_name should be part of the id.
  attr_accessor :id, :file_name
  alias druid id

  attr_accessor :canonical_url, :transformation

  # @return [RestrictedImage] the restricted version of this image
  def restricted
    RestrictedImage.new(transformation: transformation,
                        id: id,
                        file_name: file_name,
                        canonical_url: canonical_url)
  end

  # @return [Hash]
  def info
    info_service.fetch(tile_size)
  end

  # this is overriden by RestrictedImage
  def tile_size
    1024
  end

  def tile_dimensions
    projection.tile_dimensions { max_tile_dimensions }
  end

  def projection
    @projection ||= Projection.new(self, transformation)
  end

  def profile
    'http://iiif.io/api/image/2/level1'
  end

  def exist?
    image_source.exist? && image_width > 0
  end

  def valid?
    exist? && image_source.valid?
  end

  delegate :image_width, :image_height, to: :info_service
  delegate :response, :etag, :mtime, to: :image_source

  private

  # @return [InfoService]
  def info_service
    @info_service ||= StacksMetadataServiceFactory.create(self)
  end

  # @return [SourceImage]
  def image_source
    @image_source ||= StacksImageSourceFactory.create(id: id,
                                                      file_name: file_name,
                                                      transformation: transformation)
  end

  # This is overriden in RestrictedImage
  def max_tile_dimensions
    projection.region_dimensions
  end
end
