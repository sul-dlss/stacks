# frozen_string_literal: true

##
# Translate legacy Stanford API image requests into IIIF API requests
class LegacyImageServiceController < ApplicationController
  before_action :load_image

  # kludge to get around Rails' overzealous URL escaping
  IDENTIFIER_SEPARATOR = 'ZZZZZZZ'

  ##
  # Redirect legacy image requests to their IIIF equivalents
  def show
    redirect_to iiif_path(iiif_options).sub(IDENTIFIER_SEPARATOR, '%2F')
  end

  private

  def iiif_options
    @image.transformation
          .to_params
          .merge(
            identifier: "#{id}#{IDENTIFIER_SEPARATOR}#{file_name}",
            download: allowed_params[:download]
          )
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
    when zoom
      "pct:#{zoom}"
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
    case
    when region && zoom
      x, y, w, h = region.split(',')
      zoom_percent = zoom.to_f / 100.0
      [x.to_i / zoom_percent, y.to_i / zoom_percent, w.to_i / zoom_percent, h.to_i / zoom_percent].map(&:to_i).join(',')
    when region
      region
    when size == 'square'
      'square'
    else
      'full'
    end
  end

  def identifier_params
    { id: id, file_name: file_name }
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

  def zoom
    allowed_params[:zoom]
  end
end
