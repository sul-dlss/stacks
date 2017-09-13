##
# Djatoka-backed implementation of StacksImage delivery
module DjatokaAdapter
  include ActiveSupport::Benchmarkable

  # @return [IO]
  def response
    benchmark "Fetch #{url}" do
      # HTTP::Response#body does response streaming
      HTTP.get(url).body
    end
  end

  # The block gets passed to https://github.com/jronallo/djatoka/blob/master/lib/djatoka/metadata.rb#L98
  def djatoka_info(&block)
    metadata.as_json(&block)
  end
  deprecate :djatoka_info

  # TODO: ask the InfoService
  def image_width
    metadata.max_width
  end

  # TODO: ask the InfoService
  def image_height
    metadata.max_height
  end

  def image_exist?
    file.path && image_width > 0
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
    @djatoka_region ||= with_retries(max_tries: 3, rescue: exceptions_to_retry) do
      iiif_req = Djatoka::IiifRequest.new(resolver, djatoka_path)
      iiif_req.region(region)
              .size(size)
              .rotation(rotation)
              .quality(quality)
              .format(format)
              .djatoka_region
    end
  end

  # TODO: deprecate this?
  def metadata
    @metadata ||= DjatokaMetadata.find(canonical_url, djatoka_path)
  end

  def djatoka_path
    "file://#{path}"
  end

  def resolver
    @resolver ||= Djatoka::Resolver.new(Settings.stacks.djatoka_url)
  end

  def exceptions_to_retry
    [Errno::ECONNRESET, Errno::ECONNREFUSED, Net::ReadTimeout]
  end
end
