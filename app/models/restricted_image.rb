# frozen_string_literal: true

# The type of image that is used if a user doesn't have
# `can? :download, stacks_image' permissions
class RestrictedImage < StacksImage
  def tile_size
    256
  end

  def profile
    ["http://iiif.io/api/image/2/level2", { "maxWidth" => 400 }]
  end

  # Overides stacks image to provide fixed dimensions
  def max_tile_dimensions
    lambda do |projection|
      return projection.explicit_tile_dimensions(absolute_restricted_size) if projection.absolute_region?
      projection.explicit_tile_dimensions(IIIF::Image::Size::BestFit.new(400, 400))
    end
  end

  private

  def absolute_restricted_size
    IIIF::Image::Size::BestFit.new(512, 512)
  end

  def restricted_size
    IIIF::Image::Size::BestFit.new(400, 400)
  end
end
