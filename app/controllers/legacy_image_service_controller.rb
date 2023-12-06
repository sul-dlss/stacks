# frozen_string_literal: true

##
# Translate legacy Stanford API image requests into IIIF API requests
class LegacyImageServiceController < ApplicationController
  before_action :load_image

  ##
  # Redirect legacy image requests to their IIIF equivalents
  def show
    # Logging to see where these requests are coming from and if we can update them to use the right path
    logger.info("  HTTP Referer: #{request.referer[0..100]}") if request.referer
    redirect_to iiif_path(iiif_options)
  end

  private

  def iiif_options
    @image.transformation
          .to_params
          .merge(id:, file_name:,
                 download: allowed_params[:download])
  end

  def allowed_params
    params.permit(:id, :file_name, :download, :format, :h, :region, :rotate, :size, :w, :zoom)
  end

  def load_image
    @image ||= StacksImage.new(stacks_image_params)
  end

  def stacks_image_params
    { transformation: iiif_params }.merge(identifier_params)
  end

  def iiif_params
    IIIF::Image::Transformation.new(
      region: iiif_region,
      rotation: allowed_params.fetch(:rotate, 0),
      quality: 'default',
      format: allowed_params[:format] || 'jpg',
      size: iiif_size
    )
  end

  def iiif_size
    case
    when allowed_params[:zoom]
      "pct:#{allowed_params[:zoom]}"
    when allowed_params[:w]
      "#{allowed_params[:w]},#{allowed_params[:h]}"
    when size
      case size
      when 'square'
        '100,100'
      when 'thumb'
        '!400,400'
      when 'small'
        'pct:6.25'
      when 'medium'
        'pct:12.5'
      when 'large'
        'pct:25'
      when 'xlarge'
        'pct:50'
      else
        'full'
      end
    else
      'full'
    end
  end

  def iiif_region
    zoomed_region = Region.new(params[:region], params[:zoom]) if params[:region] && params[:zoom]
    case
    when zoomed_region
      zoomed_region.to_iiif_region
    when region
      region
    when size == 'square'
      'square'
    else
      'full'
    end
  end

  def identifier_params
    { id:, file_name: }
  end

  def id
    allowed_params[:id]
  end

  def file_name
    allowed_params[:file_name]
  end

  def region
    allowed_params[:region]
  end

  def size
    allowed_params[:size]
  end

  # A subset of an image defined by a region and zoom level
  class Region
    def initialize(raw_region, raw_zoom)
      raise ActionController::RoutingError, 'zoom is invalid' unless /\A\d*\.?\d+\z/.match?(raw_zoom)
      raise ActionController::RoutingError, 'region is invalid' unless /\A(\d+,){0,3}\d+\z/.match?(raw_region)

      @zoom_percent = raw_zoom.to_f / 100.0
      @x, @y, @w, @h = raw_region.split(',')
    end

    attr_reader :zoom_percent, :x, :y, :w, :h

    def to_iiif_region
      [x.to_i / zoom_percent, y.to_i / zoom_percent, w.to_i / zoom_percent, h.to_i / zoom_percent].map(&:to_i).join(',')
    end
  end
end
