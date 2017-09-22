# A projection is the result of a StacksImage put through a Iiif::Transformation
class Projection
  THUMBNAIL_BOUNDS = Iiif::Dimension.new(width: 400, height: 800)
  TILE_BOUNDS = Iiif::Dimension.new(width: 512, height: 512)

  def initialize(image, transformation)
    @image = image
    @transformation = transformation
  end

  def thumbnail?
    (transformation.region.is_a?(Iiif::Region::Full) ||
    transformation.region.is_a?(Iiif::Region::Square)) &&
      tile_dimensions.enclosed_by?(THUMBNAIL_BOUNDS)
  end

  def tile?
    absolute_region? && tile_dimensions.enclosed_by?(TILE_BOUNDS)
  end

  def region_dimensions
    case transformation.region
    when Iiif::Region::Full
      scaled_region_dimensions
    when Iiif::Region::Percent
      raise NotImplementedError, "Percent regions are not yet supported"
    when Iiif::Region::Absolute
      transformation.region.dimensions
    else
      raise ArgumentError, "Unknown region format #{transformation.region}"
    end
  end

  def explicit_tile_dimensions(requested_size)
    height = if requested_size.is_a?(Iiif::Size::Width)
               requested_size.height_for_aspect_ratio(region_dimensions.aspect)
             else
               requested_size.height
             end

    width = if requested_size.is_a?(Iiif::Size::Height)
              requested_size.width_for_aspect_ratio(region_dimensions.aspect)
            else
              requested_size.width
            end
    Iiif::Dimension.new(width: width, height: height)
  end

  def absolute_region?
    transformation.region.instance_of? Iiif::Region::Absolute
  end

  delegate :accessable_by?, to: :image

  private

  attr_reader :transformation, :image

  # @return [Iiif::Dimension]
  def tile_dimensions
    size = transformation.size
    case size
    when Iiif::Size::Percent
      scaled_tile_dimensions(size.scale)
    when Iiif::Size::Max, Iiif::Size::Full
      image.max_tile_dimensions.call(self)
    else
      explicit_tile_dimensions(size)
    end
  end

  # @param scale [Float] scale factor between 0 and 1
  # @return [Iiif::Dimension]
  def scaled_tile_dimensions(scale)
    region_dimensions.scale(scale)
  end

  def scaled_region_dimensions
    # TODO: scaling for Region::Percent
    Iiif::Dimension.new(width: image.image_width, height: image.image_height)
  end
end
