##
# Images in the image stacks
class StacksImage < StacksFile
  include DjatokaAdapter

  attr_accessor :canonical_url, :size, :region, :rotation, :quality, :format

  def tile_dimensions
    if size =~ /^!?\d*,\d*$/
      explicit_tile_dimensions
    elsif region_dimensions
      scaled_tile_dimensions
    else
      [Float::INFINITY, Float::INFINITY]
    end
  end

  def region_dimensions
    case region
    when 'full', /^pct/
      scaled_region_dimensions
    when /^(\d+),(\d+),(\d+),(\d+)$/
      explicit_region_dimensions
    end
  end

  def thumbnail?
    w, h = tile_dimensions
    (region == 'full' || region == 'square') && w <= 400 && h <= 800
  end

  def tile?
    w, h = tile_dimensions
    (region =~ /^(\d+),(\d+),(\d+),(\d+)$/) && w <= 512 && h <= 512
  end

  def druid
    id
  end

  def path
    path = super

    path + '.jp2' if path
  end

  def exist?
    image_exist?
  end

  def valid?
    image_valid?
  end

  private

  # rubocop:disable Metrics/AbcSize
  def explicit_tile_dimensions
    dim = size.delete('!').split(',', 2)

    if dim[0].blank? || dim[1].blank?
      rdim = region_dimensions
      dim[0] = (rdim[0] / rdim[1].to_f) * dim[1].to_i if dim[0].blank?
      dim[1] = (rdim[1] / rdim[0].to_f) * dim[0].to_i if dim[1].blank?
    end

    dim.map(&:to_i)
  end
  # rubocop:enable Metrics/AbcSize

  def scaled_tile_dimensions
    scale = case size
            when 'full'
              1.0
            when /^pct:/
              size.sub(/^pct:/, '').to_f / 100
            else
              1.0
            end

    region_dimensions.map { |i| i * scale }
  end

  def explicit_region_dimensions
    m = region.match(/^(\d+),(\d+),(\d+),(\d+)$/)
    [m[3], m[4]].map(&:to_i)
  end

  def scaled_region_dimensions
    scale = case region
            when 'full'
              1.0
            when /^pct:/
              region.sub(/^pct:/, '').to_f / 100
            else
              1.0
            end
    [image_width, image_height].map { |i| i * scale }
  end
end
