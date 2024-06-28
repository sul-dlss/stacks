# frozen_string_literal: true

# A projection is the result of a StacksImage put through a IIIF::Image::Transformation
class Projection
  THUMBNAIL_BOUNDS = IIIF::Image::Dimension.new(width: 400, height: 400)
  TILE_BOUNDS = IIIF::Image::Dimension.new(width: 512, height: 512)

  def self.thumbnail(image)
    new(image, IIIF::Image::Transformation.new(size: THUMBNAIL_BOUNDS, region: IIIF::Image::Region::Full.new))
  end

  # @param [StacksImage] image
  # @transformation [IIIF::Image::Transformation] transformation
  def initialize(image, transformation)
    @image = image
    @transformation = transformation
  end

  def thumbnail?
    (transformation.region.is_a?(IIIF::Image::Region::Full) ||
    transformation.region.is_a?(IIIF::Image::Region::Square)) &&
      (tile_dimensions.enclosed_by?(THUMBNAIL_BOUNDS) || transformation.size.is_a?(IIIF::Image::Size::BestFit))
  end

  def tile?
    absolute_region? && tile_dimensions.enclosed_by?(TILE_BOUNDS)
  end

  def region_dimensions
    case transformation.region
    when IIIF::Image::Region::Full
      scaled_region_dimensions
    when IIIF::Image::Region::Percent
      raise NotImplementedError, "Percent regions are not yet supported"
    when IIIF::Image::Region::Absolute
      transformation.region.dimensions
    when IIIF::Image::Region::Square
      square_region_dimensions
    else
      raise ArgumentError, "Unknown region format #{transformation.region}"
    end
  end

  def explicit_tile_dimensions(requested_size)
    height = if requested_size.is_a?(IIIF::Image::Size::Width)
               requested_size.height_for_aspect_ratio(region_dimensions.aspect)
             else
               requested_size.height
             end

    width = if requested_size.is_a?(IIIF::Image::Size::Height)
              requested_size.width_for_aspect_ratio(region_dimensions.aspect)
            else
              requested_size.width
            end
    IIIF::Image::Dimension.new(width:, height:)
  end

  def absolute_region?
    transformation.region.instance_of? IIIF::Image::Region::Absolute
  end

  def valid?
    image.exist? && image_source.valid?
  end

  delegate :object_thumbnail?, :stacks_file, to: :image

  delegate :response, to: :image_source

  attr_reader :transformation, :image

  private

  # @return [IIIF::Image::Dimension]
  def tile_dimensions
    size = transformation.size
    case size
    when IIIF::Image::Size::Percent
      scaled_tile_dimensions(size.scale)
    when IIIF::Image::Size::Max, IIIF::Image::Size::Full
      image.max_tile_dimensions.call(self)
    when IIIF::Image::Size::BestFit
      max_size = image.max_tile_dimensions.call(self)
      if size.width <= max_size.width && size.height <= max_size.height
        explicit_tile_dimensions(size)
      else
        explicit_tile_dimensions(max_size)
      end
    else
      explicit_tile_dimensions(size)
    end
  end

  # @param scale [Float] scale factor between 0 and 1
  # @return [IIIF::Image::Dimension]
  def scaled_tile_dimensions(scale)
    region_dimensions.scale(scale)
  end

  def scaled_region_dimensions
    # TODO: scaling for Region::Percent
    IIIF::Image::Dimension.new(width: image.image_width, height: image.image_height)
  end

  def square_region_dimensions
    size = [image.image_width, image.image_height].min
    IIIF::Image::Dimension.new(width: size, height: size)
  end

  # @return [IiifImage]
  def image_source
    @image_source ||= IiifImage.new(stacks_file:, transformation: real_transformation)
  end

  def real_transformation
    return transformation unless (image.is_a? RestrictedImage) || use_original_size?

    IIIF::Image::Transformation.new(
      region: transformation.region,
      size: restricted_size,
      rotation: transformation.rotation,
      quality: transformation.quality,
      format: transformation.format
    )
  end

  def restricted_size
    size = transformation.size
    case size
    when IIIF::Image::Size::BestFit
      max_size = max_image_size
      if size.width <= max_size.width && size.height <= max_size.height
        size
      else
        max_size
      end
    when IIIF::Image::Size::Max, IIIF::Image::Size::Full
      image.max_size(self)
    else
      size
    end
  end

  # For a full image request, if the requested width and height are larger than the original image,
  # this method will return true
  # If this is a percentage region, return false.
  # Region_dimensions, which is called from image.max_tile_dimensions, will raise an error for percentage regions.
  def use_original_size?
    return false if transformation.region.is_a? IIIF::Image::Region::Percent

    size = transformation.size
    max_size = image.max_tile_dimensions.call(self)
    (size.is_a? IIIF::Image::Size::BestFit) && max_size.width < size.width && max_size.height < size.height
  rescue NotImplementedError, ArgumentError => e
    Honeybadger.notify(e, error_message: "Size check error for #{transformation.inspect}") if Rails.env.production?
    false
  end

  # The original restricted image function used max_size, but the StacksImage class does not have that method
  # Since we are using the restricted image block for both RestrictedImage and StacksImage, we check
  # which method is available
  def max_image_size
    image.respond_to?(:max_size) ? image.max_size(self) : dimensions_to_size(image.max_tile_dimensions.call(self))
  end

  # StacksImage has max_tile_dimensions, which returns dimensions
  # We need to create a Size object in order to pass back to create the Iiif image object for image_source
  def dimensions_to_size(dimensions)
    IIIF::Image::Size::BestFit.new(dimensions.width, dimensions.height)
  end
end
