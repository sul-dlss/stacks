module RiiifAdapter
  Riiif::Image.file_resolver = Class.new(Riiif::FileSystemFileResolver) do
    def path(id)
      id
    end
  end.new

  def response
    iiif_region
  end

  def info
    image.info.tap { |x| yield x if block_given? }
  end

  private

  def iiif_region
    image.render(region: region, size: size, quality: quality, rotation: rotation, format: format)
  end

  def image
    Riiif::Image.new(path)
  end
end
