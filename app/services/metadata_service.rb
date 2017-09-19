# frozen_string_literal: true

# @abstract Fetch image information
# Extend this class for each implementation that can get image information.
class MetadataService
  # @param image_id [StacksIdentifier]
  # @param canonical_url [String]
  def initialize(image_id:, canonical_url:)
    @image_id = image_id
    @canonical_url = canonical_url
  end

  # @return [Hash] a data structure representing the IIIF info response
  def fetch(_tile_size); end

  def image_width; end

  def image_height; end

  attr_reader :image_id, :canonical_url
end
