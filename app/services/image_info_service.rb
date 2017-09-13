# frozen_string_literal: true

# Produces iiif info.json responses
class ImageInfoService
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
    info = current_image.info
    info['profile'] = current_image.profile
    info['sizes'] = [{ width: 400, height: 400 }] unless current_image.maybe_downloadable?

    service = services
    info['service'] = service if service
    info
  end

  # @return [String,Array<String>,NilClass] return a string if there is one service,
  #    a array if there are two services or nil if there are none.
  def services
    services = []
    unless downloadable_anonymously
      services << AuthService.to_iiif(context) if current_image.stanford_restricted?
      services << LocationService.to_iiif(context) if current_image.restricted_by_location?
    end
    return nil if services.empty?
    return services.first if services.one?
    services
  end
end
