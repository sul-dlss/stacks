# The type of image that is used if a user doesn't have
# `can? :download, stacks_image' permissions
class RestrictedImage < StacksImage
  # TODO: remove tight coupling to djatoka
  # @return [Mash]
  def info
    djatoka_info do |md|
      md.tile_width = 256
      md.tile_height = 256
    end
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
