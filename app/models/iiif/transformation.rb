module Iiif
  # A data object that describes the IIIF request
  class Transformation
    def initialize(region:, size:, rotation: '0', quality: 'default', format: 'jpg')
      @region = region
      @size = size
      @rotation = rotation
      @quality = quality
      @format = format
    end

    attr_reader :region, :size, :rotation, :quality, :format

    def to_params
      { region: region,
        size: size,
        rotation: rotation,
        quality: quality,
        format: format }
    end
  end
end
