module DjatokaAdapter
  def response
    return to_enum(:response) unless block_given?

    benchmark "Fetch #{url}" do
      client.get(url) do |req|
        req.on_body do |_, chunk|
          yield chunk
        end
      end
    end
  end

  def info(&block)
    metadata.as_json(&block)
  end

  def image_width
    metadata.max_width
  end

  def image_height
    metadata.max_height
  end

  def image_exist?
    path && image_width > 0
  end

  private

  def url
    djatoka_region.url
  end

  def djatoka_region
    @djatoka_region ||= begin
      iiif_req = Djatoka::IiifRequest.new(resolver, path)
      iiif_req.region(region)
              .size(size)
              .rotation(rotation)
              .quality(quality)
              .format(format)
              .djatoka_region
    end
  end

  def metadata
    @metadata ||= DjatokaMetadata.find(canonical_url, path)
  end

  def resolver
    @resolver ||= Djatoka::Resolver.new(Settings.stacks.djatoka_url)
  end

  def client
    @client ||= Hurley::Client.new
  end
end
