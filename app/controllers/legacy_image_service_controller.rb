class LegacyImageServiceController < ApplicationController
  before_action :load_image

  def show
    if params[:format] == 'xml'
    elsif params[:format] == 'json'
    else
      redirect_to iiif_path(identifier: "#{params[:id]}ZZZZZZZ#{file_name}",
                           region: @image.region,
                           size: @image.size,
                           rotation: @image.rotation || 0,
                           quality: @image.quality,
                           format: @image.format).sub('ZZZZZZZ', '%2F')
    end
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

  def iiif_size
    case
    when params[:zoom]
      "pct:#{params[:zoom]}"
    when params[:w]
      "#{params[:w]},#{params[:h]}"
    when size
      case size
      when 'square'
        "100,100"
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
    when params[:region] && params[:zoom]
      x,y,w,h = params[:region].split(',').map(&:to_i)
      zoom = params[:zoom].to_i / 100.0
      [x / zoom, y / zoom, w / zoom, h / zoom].map(&:to_i).join(',')
    when params[:region]
      params[:region]
    when size == 'square'
      'square'
    else
      'full'
    end
  end

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