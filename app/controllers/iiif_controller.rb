##
# API for delivering IIIF-compatible images and image tiles
class IiifController < ApplicationController
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
    raise ActionController::MissingFile, 'File Not Found' unless current_image.valid?
    return unless stale?(cache_headers)
    authorize! :read, current_image
    expires_in 10.minutes, public: anonymous_ability.can?(:read, current_image)

    set_image_response_headers

    self.content_type = Mime::Type.lookup_by_extension(format_param).to_s
    self.response_body = current_image.response
  end

  ##
  # IIIF info.json endpoint
  def metadata
    raise ActionController::MissingFile, 'File Not Found' unless current_image.exist?

    return unless stale?(cache_headers)

    if degraded? && !degraded_identifier?
      redirect_to iiif_metadata_url(identifier: degraded_identifier)
      return
    end

    expires_in 10.minutes, public: false
    authorize! :read_metadata, current_image

    respond_to do |format|
      format.any(:json, :jsonld) do
        render json: image_info
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
      ImageInfoService.info(
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

  def cache_headers
    return {} unless current_image.exist?

    {
      etag: [current_image.etag, current_user.try(:etag)],
      last_modified: current_image.mtime,
      public: anonymous_ability.can?(:read, current_image),
      template: false
    }
  end

  def set_image_response_headers
    set_attachment_content_disposition_header if allowed_params[:download]
  end

  def set_attachment_content_disposition_header
    response.headers['Content-Disposition'] = "attachment;filename=#{identifier_params[:file_name]}.#{format_param}"
  end

  def current_image
    @image ||= begin
                 img = model.new(stacks_image_params)
                 can?(:download, img) ? img : img.restricted
               end
  end

  def stacks_image_params
    { transformation: transformation }.merge(identifier_params).merge(canonical_params)
  end

  def transformation
    return unless allowed_params.key?(:size)
    IiifTransformation.new(region: allowed_params[:region],
                           size: allowed_params[:size],
                           rotation: allowed_params[:rotation],
                           quality: allowed_params[:quality],
                           format: allowed_params[:format])
  end

  def identifier_params
    id, file_name = escaped_identifier.split('%2F')
    id.sub!(/^degraded_/, '')

    { id: id, file_name: file_name }
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
    headers['Link'] = '<http://iiif.io/api/image/2/level1.json>;rel="profile"'
  end

  # We consider an image to be degraded if the user isn't current able to download it, but if they
  # login as a stanford user, they will be able to.
  def degraded?
    !can?(:access, current_image) && generic_stanford_webauth_ability.can?(:access, current_image) ||
      !can?(:download, current_image) && generic_stanford_webauth_ability.can?(:download, current_image)
  end
end
