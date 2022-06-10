# frozen_string_literal: true

##
# API for delivering IIIF-compatible images and image tiles
class IiifController < ApplicationController
  skip_forgery_protection

  before_action :add_iiif_profile_header

  rescue_from ActionController::MissingFile do
    render plain: 'File not found', status: :not_found
  end

  ##
  # Image delivery, streamed from the image server backend
  def show
    projection = current_image.projection_for(transformation)
    raise ActionController::MissingFile, 'File Not Found' unless projection.valid?

    return unless stale?(**cache_headers_show(projection))

    authorize! :read, projection
    expires_in cache_time, public: anonymous_ability.can?(:read, projection)

    set_image_response_headers

    self.content_type = Mime::Type.lookup_by_extension(iiif_params[:format]).to_s
    self.status = projection.response.status
    self.response_body = projection.response.body
  end

  ##
  # IIIF info.json endpoint
  # rubocop:disable Metrics/PerceivedComplexity
  def metadata
    unless Rails.env.development?
      raise ActionController::MissingFile, 'File Not Found' unless current_image.exist?
    end

    return unless stale?(**cache_headers_metadata)

    if !degraded? && degradable?
      redirect_to degraded_iiif_metadata_url(id: identifier_params[:id], file_name: identifier_params[:file_name])
      return
    end

    expires_in cache_time, public: false
    authorize! :read_metadata, current_image

    status = if degraded? || can?(:access, current_image)
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
  # rubocop:enable Metrics/PerceivedComplexity

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

  def iiif_params
    params.permit(:region, :size, :rotation, :quality, :format)
  end

  # called when CanCan::AccessDenied error is raised, typically by authorize!
  #   Should only be here if
  #   a)  access not allowed (send to super)  OR
  #   b)  need user to login to determine if access allowed
  def rescue_can_can(exception)
    if degradable? && !current_user.webauth_user?
      redirect_to auth_iiif_url(iiif_params.to_h.merge(identifier_params).merge(download: params[:download]).symbolize_keys)
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
    set_attachment_content_disposition_header if params[:download]
  end

  def set_attachment_content_disposition_header
    filename = [File.basename(identifier_params[:file_name], '.*'), iiif_params[:format]].join('.')
    response.headers['Content-Disposition'] = "attachment;filename=\"#{filename}\""
  end

  def current_image
    @image ||= begin
                 img = StacksImage.new(stacks_image_params)
                 can?(:download, img) ? img : img.restricted
               end
  end

  def identifier_params
    return params.slice(:id, :file_name) if params[:id] && params[:file_name]

    id, file_name = params[:identifier].sub('/', '%2F').split('%2F', 2)
    { id: id, file_name: file_name }
  end

  def stacks_image_params
    # Generate the canonical URL manually to avoid cases where the requested
    # URL encodes the / between id and filename as %2F, but the canonical URL
    # does not. See: https://github.com/sul-dlss/stacks/issues/864
    identifier = ERB::Util.url_encode(identifier_params[:id])
    filename = ERB::Util.url_encode(identifier_params[:file_name])
    root = iiif_root_url(host: request.host_with_port)
    canonical_url = "#{root}/#{identifier}%2F#{filename}"
    {
      id: identifier_params[:id],
      file_name: identifier_params[:file_name] + '.jp2',
      canonical_url: canonical_url
    }
  end

  # @return [IIIF::Image::Transformation] returns the transformation for the parameters
  def transformation
    return unless iiif_params.key?(:size)

    IIIF::Image::OptionDecoder.decode(iiif_params)
  end

  def add_iiif_profile_header
    headers['Link'] = '<http://iiif.io/api/image/2/level2.json>;rel="profile"'
  end

  # We consider an image to be degraded if the user isn't currently able to download it, but if they
  # login as a stanford user, they will be able to.
  def degradable?
    stanford_ability = User.stanford_generic_user.ability

    # accessible if the user authenticates
    degradable = !can?(:access, current_image) && stanford_ability.can?(:access, current_image)
    # downloadable if the user authenticates
    degradable ||= !can?(:download, current_image) && stanford_ability.can?(:download, current_image)
    # thumbnail-only
    degradable ||= !can?(:access, current_image) && can?(:read, Projection.thumbnail(current_image))

    degradable
  end

  def degraded?
    params[:degraded].present?
  end

  def cache_time
    return 1.minute if current_image.cdl_restricted?

    10.minutes
  end
end
