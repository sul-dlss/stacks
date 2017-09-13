# A data object that describes the IIIF request
class IiifTransformation
  def initialize(region:, size:, rotation:, quality:, format:)
    @region = region
    @size = size
    @rotation = rotation
    @quality = quality
    @format = format
  end

  attr_reader :region, :size, :rotation, :quality, :format
end
