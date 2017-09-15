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

  attr_reader :image_id, :canonical_url
end
