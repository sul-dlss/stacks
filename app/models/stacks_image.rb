# frozen_string_literal: true

##
# An image that can be delivered over the IIIF endpoint
class StacksImage
  include StacksRights
  include ActiveModel::Model

  attr_accessor :id
  attr_accessor :canonical_url, :transformation

  # @return [RestrictedImage] the restricted version of this image
  def restricted
    RestrictedImage.new(transformation: transformation,
                        id: id,
                        canonical_url: canonical_url)
  end

  # @return [Hash]
  def info
    info_service.fetch(tile_size)
  end

  # this is overriden by RestrictedImage
  # nil implies whatever is best for the implementation.
  def tile_size
    nil
  end

  def profile
    'http://iiif.io/api/image/2/level2'
  end

  def exist?
    file_source.readable? && image_width.positive?
  end

  delegate :image_width, :image_height, to: :info_service
  delegate :etag, :mtime, to: :file_source

  # This is overriden in RestrictedImage
  def max_tile_dimensions
    ->(projection) { projection.region_dimensions }
  end

  def projection_for(transformation)
    Projection.new(self, transformation)
  end

  private

  # @return [StacksFile]
  def file_source
    @file_source ||= StacksFile.new(id: id)
  end

  # @return [InfoService]
  def info_service
    @info_service ||= StacksMetadataServiceFactory.create(image_id: id, canonical_url: canonical_url)
  end
end
