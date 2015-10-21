##
# API for delivering IIIF-compatible images and image tiles
class IiifController < ApplicationController
  before_action :load_image
  before_action :add_iiif_profile_header

  rescue_from ActionController::MissingFile do
    render text: 'File not found', status: :not_found
  end

  before_action do
    fail ActionController::MissingFile, 'File Not Found' unless @image.image_exist?
  end

  def show
    return unless stale?(cache_headers)
    authorize! :read, @image
    expires_in 10.minutes, public: anonymous_ability.can?(:read, @image)
    self.content_type = Mime::Type.lookup_by_extension(params[:format]).to_s
    self.response_body = @image.response
  end

  def metadata
    return unless stale?(cache_headers)
    authorize! :read_metadata, @image
    expires_in 10.minutes, public: anonymous_ability.can?(:read, @image)

    self.content_type = 'application/json'
    self.response_body = JSON.pretty_generate(image_info)
  end

  private

  def rescue_can_can(exception)
    if current_user
      super(exception)
    else
      redirect_to auth_iiif_url(params.symbolize_keys.tap { |x| x[:identifier].gsub!('/', '%2F') })
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

    info
  end
  # rubocop:enable Metrics/MethodLength

  def image_params
    params.except(:identifier, :controller, :action).merge(identifier_params).merge(canonical_params)
  end

  def identifier_params
    id, file_name = params[:identifier].split(Regexp.union(%r{/}, /%2F/))
    { id: id, file_name: file_name }
  end

  def canonical_params
    { canonical_url: iiif_base_url(identifier: params[:identifier].gsub('/', '%2F'), host: request.host_with_port) }
  end

  def add_iiif_profile_header
    headers['Link'] = '<http://iiif.io/api/image/2/level1.json>;rel="profile"'
  end
end
