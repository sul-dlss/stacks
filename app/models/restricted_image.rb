# frozen_string_literal: true

# The type of image that is used if a user doesn't have
# `can? :download, stacks_image' permissions
class RestrictedImage < StacksImage
  # TODO: Remove? https://github.com/sul-dlss/stacks/issues/179
  def v1_tile_dimensions
    { 'tile_width' => 256, 'tile_height' => 256 }
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
