# frozen_string_literal: true

# Produces iiif info.json responses
class IiifInfoService
  ASPECT_EXAGGERATION = 40.0
  MAX_SIZE_ALLOWED = 200_000_000

  # A helper method to instantiate and produce the json
  # @param current_image [StacksImage,RestrictedImage] the image to get the information for
  # @param downloadable_anonymously [Boolean] can the resource be downloaded anonymously?
  # @param context [IiifController] the context for the routing helpers (has hostname)
  # @return [Hash] a data structure to that expresses the info.json response
  def self.info(current_image, downloadable_anonymously, context)
    new(current_image, downloadable_anonymously, context).info
  end

  # @param current_image [StacksImage,RestrictedImage] the image to get the information for
  # @param downloadable_anonymously [Boolean] can the resource be downloaded anonymously?
  # @param context [IiifController] the context for the routing helpers (has hostname)
  def initialize(current_image, downloadable_anonymously, context)
    @current_image = current_image
    @downloadable_anonymously = downloadable_anonymously
    @context = context
  end

  attr_reader :current_image, :downloadable_anonymously, :context

  # @return [Hash] a data structure to that expresses the info.json response
  def info
    current_image.info.tap do |info|
      info['profile'] = current_image.profile
      info['sizes'] = sizes(info['sizes'])
      info['sizes'] = thumbnail_only_size unless current_image.maybe_downloadable?

      service = services unless downloadable_anonymously
      info['service'] = service if service
      info['tiles'] = tiles(info['tiles']) if info['tiles']
    end
  end

  ##
  # Trims the provided sizes so that known large undownloadable sizes are not
  # returned
  def sizes(sizes)
    sizes.to_a.filter do |size|
      size['width'].to_f * size['height'].to_f < MAX_SIZE_ALLOWED
    end
  end

  ##
  # Modifies the tiles height/width if the of the provided tiles are significantly
  # exaggerated. This is so that too large of an image is not returned and that
  # browser canvas APIs can handle the returned images without failing.
  def tiles(tiles)
    width = tiles[0]['width'].to_f
    height = tiles[0]['height'].to_f
    minimum = [width, height].min
    aspect_ratio = width / height
    if aspect_ratio < (1 / ASPECT_EXAGGERATION) || aspect_ratio > ASPECT_EXAGGERATION
      tiles[0]['width'] = minimum
      tiles[0]['height'] = minimum
    end
    tiles
  end

  # @return [String,Array<String>,NilClass] return a string if there is one service,
  #    a array if there are two services or nil if there are none.
  def services
    services = []
    services << AuthService.to_iiif(context) if current_image.stanford_restricted?
    services << LocationService.to_iiif(context) if current_image.restricted_by_location?
    return nil if services.empty?

    services.one? ? services.first : services
  end

  def thumbnail_only_size
    aspect_ratio = Projection.thumbnail(current_image).region_dimensions.aspect.to_f

    if aspect_ratio > 1
      [{ width: 400, height: (400 / aspect_ratio).floor }]
    else
      [{ width: (400 * aspect_ratio).floor, height: 400 }]
    end
  end
end
