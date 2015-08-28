class LegacyImageServiceController < ApplicationController
  include ActionController::Redirecting
  include Rails.application.routes.url_helpers

  before_action :load_image

  SIZE_CATEGORIES = %w(square thumb small medium large xlarge full)
  SIZE_REGEX = /_(#{SIZE_CATEGORIES.join('|')})$/i


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
    when params[:region]
      params[:region]
    when size == 'square'
      image = StacksImage.new(identifier_params)
      h = image.image_width
      w = image.image_height
      min, max = [h,w].minmax
      offset = (max - min) / 2

      if h >= w
        "0,#{offset},#{min},#{min}"
      else
        "#{offset},0,#{min},#{min}"
      end
    else
      'full'
    end
  end

  def identifier_params
    { id: params[:id], file_name: file_name }
  end

  def file_name
    if params[:file_name] =~ SIZE_REGEX
      params[:file_name].sub(SIZE_REGEX, '')
    else
      params[:file_name]
    end
  end

  def size
    @size = if params[:size]
      params[:size]
    elsif params[:file_name] =~ SIZE_REGEX
      m = params[:file_name].match(SIZE_REGEX)
      m[1] if m
    end
  end
end