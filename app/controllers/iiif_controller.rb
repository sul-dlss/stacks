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

    begin
      return unless stale?(**cache_headers_show(projection))
    rescue StacksFile::NotFound
      raise ActionController::MissingFile, 'File not found'
    end

    authorize! :read, projection
    expires_in cache_time, public: anonymous_ability.can?(:read, projection)

    set_image_response_headers

    TrackDownloadJob.perform_later(
      druid: identifier_params[:id],
      file: download_filename,
      user_agent: request.user_agent,
      ip: request.remote_ip
    )

    self.content_type = Mime::Type.lookup_by_extension(iiif_params[:format]).to_s
    self.status = projection.response.status
    self.response_body = projection.response.body
  end

  ##
  # IIIF info.json endpoint
  # rubocop:disable Metrics/PerceivedComplexity
  def metadata
    raise ActionController::MissingFile, 'File Not Found' if !Rails.env.development? && !current_image.exist?

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
        render json: image_info, status:
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
      img = StacksImage.new(stacks_file:, canonical_url:)
      can?(:download, img) ? img : img.restricted
    end
  end

  def identifier_params
    return params.permit(:id, :file_name).to_h if params[:id] && params[:file_name]

    id, file_name = params[:identifier].sub('/', '%2F').split('%2F', 2)
    { id:, file_name: }
  end

  # If we ever update identifier_params[:file_name] to be the md5 filename
  # We need to make sure this still works with the human filename for apps like Parker
  # https://dms-data.stanford.edu/data/manifests/Parker/wz026zp2442/manifest.json
  def download_filename
    [File.basename(identifier_params[:file_name], '.*'), iiif_params[:format]].join('.')
  end

  def canonical_url
    iiif_base_url(id: identifier_params[:id], file_name: identifier_params[:file_name], host: request.host_with_port)
  end

  def stacks_file
    StacksFile.new(
      file_name: "#{identifier_params[:file_name]}.jp2",
      cocina: Cocina.find(identifier_params[:id])
    )
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
    10.minutes
  end
end
