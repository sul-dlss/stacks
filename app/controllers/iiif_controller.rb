class IiifController < ApplicationController
  include Rails.application.routes.url_helpers

  before_action :load_image
  before_action :add_iiif_profile_header

  def show
    fail "File Not Found" unless @image.exist?
    authorize! :read, @image
    self.content_type = mime_type(params[:format])
    self.response_body = @image.response
  end

  def metadata
    info = @image.info do |md|
      if can? :download, @image
        md.tile_width = 1024
        md.tile_height = 1024
      else
        md.tile_width = 256
        md.tile_height = 256
      end
    end

    unless can? :download, @image
      info['sizes'] = [{width: 400, height: 400}]
    end

    self.content_type = 'application/json'
    self.response_body = JSON.pretty_generate(info)
  end

  private

  def mime_type(format)
    case format
    when 'jpg'
      'image/jpeg'
    when 'tif'
      'image/tiff'
    when 'png'
      'image/png'
    when 'gif'
      'image/gif'
    when 'jp2'
      'image/jp2'
    when 'pdf'
      'application/pdf'
    when 'webp'
      'image/webp'
    end
  end

  def load_image
    @image ||= StacksImage.new(image_params)
  end

  def image_params
    params.except(:identifier, :controller, :action).merge(identifier_params).merge(canonical_params)
  end

  def identifier_params
    id, file_name = params[:identifier].split(%r{[/(%2F)]})
    { id: id, file_name: file_name }
  end

  def canonical_params
    { canonical_url: iiif_base_url(identifier: params[:identifier].gsub('/', '%2F'), host: request.host_with_port) }
  end

  def add_iiif_profile_header
    headers['Link'] = '<http://iiif.io/api/image/2/level1.json>;rel="profile"'
  end
end
