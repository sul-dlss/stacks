# frozen_string_literal: true

##
# An image that can be delivered over the IIIF endpoint
class StacksImage
  def initialize(stacks_file:, canonical_url: nil, transformation: nil)
    @stacks_file = stacks_file
    @canonical_url = canonical_url
    @transformation = transformation
  end

  attr_accessor :canonical_url, :transformation, :stacks_file

  # @return [RestrictedImage] the restricted version of this image
  def restricted
    RestrictedImage.new(stacks_file:,
                        transformation:,
                        canonical_url:)
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
    ['http://iiif.io/api/image/2/level2.json']
  end

  def exist?
    readable? && image_width.positive?
  end

  delegate :image_width, :image_height, to: :info_service
  delegate :etag, :mtime, :stacks_rights, :readable?, to: :stacks_file

  # This is overriden in RestrictedImage
  def max_tile_dimensions
    ->(projection) { projection.region_dimensions }
  end

  def projection_for(transformation)
    Projection.new(self, transformation)
  end

  private

  # @return [InfoService]
  def info_service
    @info_service ||= IiifMetadataService.new(id: stacks_file.id, file_name: stacks_file.file_name, canonical_url:)
  end

  delegate :rights, :maybe_downloadable?, :object_thumbnail?,
           :stanford_restricted?, :restricted_by_location?, to: :stacks_rights
end
