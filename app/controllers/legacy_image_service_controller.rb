##
# Translate legacy Stanford API image requests into IIIF API requests
class LegacyImageServiceController < ApplicationController
  before_action :load_image

  # kludge to get around Rails' overzealous URL escaping
  IDENTIFIER_SEPARATOR = 'ZZZZZZZ'

  ##
  # Redirect legacy image requests to their IIIF equivalents
  def show
    redirect_to iiif_path(identifier: "#{params[:id]}#{IDENTIFIER_SEPARATOR}#{file_name}",
                          download: params[:download],
                          region: @image.region,
                          size: @image.size,
                          rotation: @image.rotation || 0,
                          quality: @image.quality,
                          format: @image.format).sub(IDENTIFIER_SEPARATOR, '%2F')
  end

  private

  def load_image
    @image ||= StacksImage.new(image_params)
  end

  def image_params
    iiif_params.merge(identifier_params)
  end

  def iiif_params
    {
      region: iiif_region,
      rotation: params[:rotate],
      quality: 'default',
      format: params[:format] || 'jpg',
      size: iiif_size
    }
  end

  # rubocop:disable Metrics/CyclomaticComplexity, Metrics/MethodLength
  def iiif_size
    case
    when params[:zoom]
      "pct:#{params[:zoom]}"
    when params[:w]
      "#{params[:w]},#{params[:h]}"
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
  # rubocop:enable Metrics/CyclomaticComplexity, Metrics/MethodLength

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def iiif_region
    case
    when params[:region] && params[:zoom]
      x, y, w, h = params[:region].split(',')
      zoom = params[:zoom].to_f / 100.0
      [x.to_i / zoom, y.to_i / zoom, w.to_i / zoom, h.to_i / zoom].map(&:to_i).join(',')
    when params[:region]
      params[:region]
    when size == 'square'
      'square'
    else
      'full'
    end
  end
  # rubocop:enable Metrics/AbcSize, Metrics/MethodLength

  def identifier_params
    { id: params[:id], file_name: file_name }
  end

  def file_name
    params[:file_name]
  end

  def size
    params[:size]
  end
end
