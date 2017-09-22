# A projection is the result of a StacksImage put through a Iiif::Transformation
class Projection
  def initialize(image, transformation)
    @image = image
    @transformation = transformation
  end

  def thumbnail?
    return false unless transformation
    width, height = tile_dimensions
    (transformation.region.is_a?(Iiif::Region::Full) ||
    transformation.region.is_a?(Iiif::Region::Square)) &&
      width <= 400 && height <= 800
  end

  def tile?
    return false unless transformation
    width, height = tile_dimensions
    absolute_region? && width <= 512 && height <= 512
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
               height_for_aspect_ratio(requested_size.width)
             else
               requested_size.height
             end

    width = if requested_size.is_a?(Iiif::Size::Height)
              width_for_aspect_ratio(requested_size.height)
            else
              requested_size.width
            end
    [width, height]
  end

  def absolute_region?
    transformation.region.instance_of? Iiif::Region::Absolute
  end

  delegate :accessable_by?, to: :image

  private

  attr_reader :transformation, :image

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

  def height_for_aspect_ratio(width)
    rwidth, rheight = region_dimensions
    (rheight / rwidth.to_f) * width
  end

  def width_for_aspect_ratio(height)
    rwidth, rheight = region_dimensions
    (rwidth / rheight.to_f) * height
  end

  def scaled_tile_dimensions(scale)
    region_dimensions.map { |dimension| dimension * scale }
  end

  def scaled_region_dimensions
    # TODO: scaling for pct regions
    # [image.image_width, image.image_height].map { |dim| dim * scale }
    [image.image_width, image.image_height]
  end
end
