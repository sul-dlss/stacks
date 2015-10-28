##
# API for delivering IIIF-compatible images and image tiles
class IiifController < ApplicationController
  before_action :load_image
  before_action :add_iiif_profile_header

  rescue_from ActionController::MissingFile do
    render text: 'File not found', status: :not_found
  end

  before_action only: :show do
    fail ActionController::MissingFile, 'File Not Found' unless @image.valid?
  end

  before_action only: :metadata do
    fail ActionController::MissingFile, 'File Not Found' unless @image.exist?
  end

  ##
  # Image delivery, streamed from the image server backend
  def show
    return unless stale?(cache_headers)
    authorize! :read, @image
    expires_in 10.minutes, public: anonymous_ability.can?(:read, @image)

    self.content_type = Mime::Type.lookup_by_extension(params[:format]).to_s
    self.response_body = @image.response
  end

  ##
  # IIIF info.json endpoint
  def metadata
    return unless stale?(cache_headers)
    authorize! :read_metadata, @image
    expires_in 10.minutes, public: anonymous_ability.can?(:read, @image)

    self.content_type = 'application/json'
    self.response_body = JSON.pretty_generate(image_info)
  end

  def metadata_options
    response.headers['Access-Control-Allow-Headers'] = 'Authorization'
    self.response_body = ''
  end

  private

  def rescue_can_can(exception)
    if current_user
      super(exception)
    else
      redirect_to auth_iiif_url(params.symbolize_keys.tap { |x| x[:identifier] = escaped_identifier })
    end
  end

  def cache_headers
    return {} unless @image.exist?

    {
      etag: [@image.etag, current_user.try(:etag)],
      last_modified: @image.mtime,
      public: anonymous_ability.can?(:read, @image),
      template: false
    }
  end

  def load_image
    @image ||= StacksImage.new(image_params)
  end

  # rubocop:disable Metrics/MethodLength
  def image_info
    info = @image.info do |md|
      if can? :download, @image
        md.tile_width = 1024
        md.tile_height = 1024
      else
        md.tile_width = 256
        md.tile_height = 256
      end
    end

    info['sizes'] = [{ width: 400, height: 400 }] unless can? :download, @image

    info['service'] = {
      '@id' => iiif_auth_api_url,
      'profile' => 'http://iiif.io/api/auth/0/login',
      'label' => 'Stanford-affiliated? Login to view',
      'service' => [
        {
          '@id' => iiif_token_api_url,
          'profile' => 'http://iiif.io/api/auth/0/token'
        }
      ]
    } unless anonymous_ability.can? :download, @image

    info
  end
  # rubocop:enable Metrics/MethodLength

  def image_params
    params.slice(:region, :size, :rotation, :quality, :format).merge(identifier_params).merge(canonical_params)
  end

  def identifier_params
    id, file_name = escaped_identifier.split('%2F')
    { id: id, file_name: file_name }
  end

  def canonical_params
    { canonical_url: iiif_base_url(identifier: escaped_identifier, host: request.host_with_port) }
  end

  # kludge to get around Rails' overzealous URL escaping
  def escaped_identifier
    params[:identifier].sub('/', '%2F')
  end

  def add_iiif_profile_header
    headers['Link'] = '<http://iiif.io/api/image/2/level1.json>;rel="profile"'
  end
end
