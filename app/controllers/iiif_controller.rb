##
# API for delivering IIIF-compatible images and image tiles
class IiifController < ApplicationController
  before_action :load_image
  before_action :add_iiif_profile_header

  rescue_from ActionController::MissingFile do
    render plain: 'File not found', status: :not_found
  end

  before_action only: :show do
    raise ActionController::MissingFile, 'File Not Found' unless current_image.valid?
  end

  before_action only: :metadata do
    raise ActionController::MissingFile, 'File Not Found' unless current_image.exist?
  end

  ##
  # Image delivery, streamed from the image server backend
  def show
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
    return unless stale?(cache_headers)

    if degraded? && !degraded_identifier?
      redirect_to iiif_metadata_url(identifier: degraded_identifier)
      return
    end

    expires_in 10.minutes, public: false
    authorize! :read_metadata, current_image

    respond_to do |format|
      format.any(:json, :jsonld) { render json: JSON.pretty_generate(image_info) }
    end
  end

  def metadata_options
    response.headers['Access-Control-Allow-Headers'] = 'Authorization'
    self.response_body = ''
  end

  private

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
    if degraded?
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
    @image
  end

  def load_image
    @image ||= StacksImage.new(stacks_image_params.merge(current_ability: current_ability))
  end

  def image_info
    info = current_image.info do |md|
      if can? :download, current_image
        md.tile_width = 1024
        md.tile_height = 1024
      else
        md.tile_width = 256
        md.tile_height = 256
      end
    end

    info['profile'] =
      if can? :download, current_image
        'http://iiif.io/api/image/2/level1'
      else
        ['http://iiif.io/api/image/2/level1', { 'maxWidth' => 400 }]
      end

    info['sizes'] = [{ width: 400, height: 400 }] unless current_image.maybe_downloadable?

    services = []
    if anonymous_ability.cannot? :download, current_image
      if current_image.stanford_restricted?
        services << {
          '@id' => iiif_auth_api_url,
          'profile' => 'http://iiif.io/api/auth/1/login',
          'label' => 'Stanford-affiliated? Login to view',
          'confirmLabel' => 'Login',
          'service' => [
            {
              '@id' => iiif_token_api_url,
              'profile' => 'http://iiif.io/api/auth/1/token'
            },
            {
              '@id' => logout_url,
              'profile' => 'http://iiif.io/api/auth/1/logout',
              'label' => 'Logout'
            }
          ]
        }
      end

      if current_image.restricted_by_location?
        services << {
          'profile' => 'http://iiif.io/api/auth/1/external',
          'label' => 'External Authentication Required',
          'confirmLabel' => 'Login',
          'failureHeader' => 'Restricted Material',
          'failureDescription' => 'Restricted content cannot be accessed from your location',
          'service' => [
            {
              '@id' => iiif_token_api_url,
              'profile' => 'http://iiif.io/api/auth/1/token'
            }
          ]
        }
      end
    end

    if services.one?
      info['service'] = services.first
    elsif services.any?
      info['service'] = services
    end

    info
  end

  def stacks_image_params
    allowed_params.slice(:region, :size, :rotation, :quality, :format).merge(identifier_params).merge(canonical_params)
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

  def degraded?
    !can?(:download, current_image) && current_image.stanford_restricted? && !current_user.webauth_user?
  end
end
