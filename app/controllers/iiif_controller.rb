# frozen_string_literal: true

##
# API for delivering IIIF-compatible images and image tiles
class IiifController < ApplicationController
  skip_forgery_protection

  before_action :ensure_valid_identifier
  before_action :add_iiif_profile_header

  # Follow the interface of Riiif
  class_attribute :model
  self.model = StacksImage

  rescue_from ActionController::MissingFile do
    render plain: 'File not found', status: :not_found
  end

  ##
  # Image delivery, streamed from the image server backend
  def show
    projection = current_image.projection_for(transformation)
    raise ActionController::MissingFile, 'File Not Found' unless projection.valid?

    return unless stale?(cache_headers_show(projection))

    authorize! :read, projection
    expires_in cache_time, public: anonymous_ability.can?(:read, projection)

    set_image_response_headers

    self.content_type = Mime::Type.lookup_by_extension(format_param).to_s
    self.status = projection.response.status
    self.response_body = projection.response.body
  end

  ##
  # IIIF info.json endpoint
  def metadata
    raise ActionController::MissingFile, 'File Not Found' unless current_image.exist?

    return unless stale?(cache_headers_metadata)

    if degraded?
      redirect_to iiif_metadata_url(identifier: degraded_identifier)
      return
    end

    expires_in cache_time, public: false
    authorize! :read_metadata, current_image

    status = if degraded_identifier? || can?(:access, current_image)
               :ok
             else
               :unauthorized
             end

    respond_to do |format|
      format.any(:json, :jsonld) do
        render json: image_info, status: status
      end
    end
  end

  def metadata_options
    response.headers['Access-Control-Allow-Headers'] = 'Authorization'
    self.response_body = ''
  end

  private

  # @return [String] the info.json body
  def image_info
    JSON.pretty_generate(
      IiifInfoService.info(
        current_image,
        anonymous_ability.can?(:download, current_image),
        self
      )
    )
  end

  def allowed_params
    params.permit(:region, :size, :rotation, :quality, :format, :identifier, :download)
  end

  def format_param
    allowed_params[:format]
  end

  # called when CanCan::AccessDenied error is raised, typically by authorize!
  #   Should only be here if
  #   a)  access not allowed (send to super)  OR
  #   b)  need user to login to determine if access allowed
  def rescue_can_can(exception)
    if degraded? && !current_user.webauth_user?
      redirect_to auth_iiif_url(allowed_params.to_h.symbolize_keys.tap { |x| x[:identifier] = escaped_identifier })
    else
      super
    end
  end

  # the cache headers for the metadata action
  def cache_headers_metadata
    cache_headers.merge(public: anonymous_ability.can?(:access, current_image))
  end

  # the cache headers for the show action
  def cache_headers_show(projection)
    # This is public if the image is public or the projection is a tile or a thumbnail
    cache_headers.merge(public: anonymous_ability.can?(:read, projection))
  end

  # generic cache headers.
  def cache_headers
    {
      etag: [current_image.etag, current_user.try(:etag)],
      last_modified: current_image.mtime,
      template: false
    }
  end

  def set_image_response_headers
    set_attachment_content_disposition_header if allowed_params[:download]
  end

  def set_attachment_content_disposition_header
    filename = [stacks_identifier.file_name_without_ext, format_param].join('.')
    response.headers['Content-Disposition'] = "attachment;filename=\"#{filename}\""
  end

  def current_image
    @image ||= begin
                 img = model.new(stacks_image_params)
                 can?(:download, img) ? img : img.restricted
               end
  end

  def stacks_image_params
    { id: stacks_identifier }.merge(canonical_params)
  end

  # @return [IIIF::Image::Transformation] returns the transformation for the parameters
  def transformation
    return unless allowed_params.key?(:size)

    IIIF::Image::OptionDecoder.decode(allowed_params)
  end

  def stacks_identifier
    @stacks_identifier ||= StacksIdentifier.new(escaped_identifier.sub(/^degraded_/, '') + '.jp2')
  end

  def canonical_params
    { canonical_url: iiif_base_url(identifier: escaped_identifier, host: request.host_with_port) }
  end

  # kludge to get around Rails' overzealous URL escaping
  def escaped_identifier
    allowed_params[:identifier].sub('/', '%2F')
  end

  def degraded_identifier
    "degraded_#{escaped_identifier}"
  end

  def degraded_identifier?
    escaped_identifier.starts_with? 'degraded'
  end

  def add_iiif_profile_header
    headers['Link'] = '<http://iiif.io/api/image/2/level2.json>;rel="profile"'
  end

  # We consider an image to be degraded if the user isn't currently able to download it, but if they
  # login as a stanford user, they will be able to.
  def degraded?
    return false if degraded_identifier?

    stanford_ability = User.stanford_generic_user.ability

    # accessible if the user authenticates
    degraded = !can?(:access, current_image) && stanford_ability.can?(:access, current_image)
    # downloadable if the user authenticates
    degraded ||= !can?(:download, current_image) && stanford_ability.can?(:download, current_image)
    # thumbnail-only
    degraded ||= !can?(:access, current_image) && can?(:read, Projection.thumbnail(current_image))

    degraded
  end

  def ensure_valid_identifier
    raise ActionController::RoutingError, "invalid identifer" unless stacks_identifier.valid?
  end

  def cache_time
    return 1.minute if current_image.cdl_restricted?

    10.minutes
  end
end
