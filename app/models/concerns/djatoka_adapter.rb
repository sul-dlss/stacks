##
# Djatoka-backed implementation of StacksImage delivery
module DjatokaAdapter
  # @return [IO]
  def response
    benchmark "Fetch #{url}" do
      # HTTP::Response#body does response streaming
      HTTP.get(url).body
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

  def image_valid?
    image_exist? && url.present?
  end

  private

  def url
    djatoka_region.url
  rescue Djatoka::IiifInvalidParam
    nil
  end

  def djatoka_region
    @djatoka_region ||= with_retries(max_tries: 3, rescue: [Errno::ECONNRESET, Errno::ECONNREFUSED, Net::ReadTimeout]) do
      iiif_req = Djatoka::IiifRequest.new(resolver, djatoka_path)
      iiif_req.region(region)
              .size(size)
              .rotation(rotation)
              .quality(quality)
              .format(format)
              .djatoka_region
    end
  end

  def metadata
    @metadata ||= DjatokaMetadata.find(canonical_url, djatoka_path)
  end

  def djatoka_path
    "file://#{path}"
  end

  def resolver
    @resolver ||= Djatoka::Resolver.new(Settings.stacks.djatoka_url)
  end
end
