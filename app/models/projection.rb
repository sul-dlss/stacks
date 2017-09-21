# A projection is the result of a StacksImage put through a Iiif::Transformation
class Projection
  def initialize(image, transformation)
    @image = image
    @transformation = transformation
  end

  def thumbnail?
    return false unless transformation
    width, height = tile_dimensions
    %w(full square).include?(transformation.region) && width <= 400 && height <= 800
  end

  def tile?
    return false unless transformation
    width, height = tile_dimensions
    absolute_region? && width <= 512 && height <= 512
  end

  def region_dimensions
    case transformation.region
    when 'full', /^pct/
      scaled_region_dimensions
    when /^(\d+),(\d+),(\d+),(\d+)$/
      explicit_region_dimensions
    else
      raise ArgumentError, "Unknown region format #{transformation.region}"
    end
  end

  # pass a block with the max dimensions
  def tile_dimensions
    size = transformation.size
    if size =~ /^!?\d*,\d*$/
      explicit_tile_dimensions(size)
    elsif size == 'max'
      image.max_tile_dimensions.call(self)
    elsif region_dimensions
      scaled_tile_dimensions
    else
      [Float::INFINITY, Float::INFINITY]
    end
  end

  def explicit_tile_dimensions(requested_size)
    height, width = requested_size.delete('!').split(',', 2)

    height = height_for_aspect_ratio(width) if height.blank?
    width = width_for_aspect_ratio(height) if width.blank?

    [height.to_i, width.to_i]
  end

  def absolute_region?
    transformation.region =~ /^(\d+),(\d+),(\d+),(\d+)$/
  end

  attr_reader :image

  private

  attr_reader :transformation

  def height_for_aspect_ratio(width)
    rheight, rwidth = region_dimensions
    (rheight / rwidth.to_f) * width.to_i
  end

  def width_for_aspect_ratio(height)
    rheight, rwidth = region_dimensions
    (rwidth / rheight.to_f) * height.to_i
  end

  def scaled_tile_dimensions
    size = transformation.size
    scale = case size
            when 'full'
              1.0
            when /^pct:/
              size.sub(/^pct:/, '').to_f / 100
            else
              1.0
            end

    region_dimensions.map { |dimension| dimension * scale }
  end

  def explicit_region_dimensions
    match = transformation.region.match(/^(\d+),(\d+),(\d+),(\d+)$/)
    [match[3], match[4]].map(&:to_i)
  end

  def scaled_region_dimensions
    scale = case transformation.region
            when 'full'
              1.0
            when /^pct:/
              # FIXME: This format of a percent region is 'pct:10,20,14,20'
              transformation.region.sub(/^pct:/, '').to_f / 100
            else
              1.0
            end
    [image.image_width, image.image_height].map { |dim| dim * scale }
  end
end
