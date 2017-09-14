# frozen_string_literal: true

# The type of image that is used if a user doesn't have
# `can? :download, stacks_image' permissions
class RestrictedImage < StacksImage
  def tile_size
    256
  end

  def profile
    ["http://iiif.io/api/image/2/level1", { "maxWidth" => 400 }]
  end

  # Overides stacks image to provide fixed dimensions
  def max_tile_dimensions
    return explicit_tile_dimensions('!512,512') if region =~ /^(\d+),(\d+),(\d+),(\d+)$/
    explicit_tile_dimensions('!400,400')
  end
end
