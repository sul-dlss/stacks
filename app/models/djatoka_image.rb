# Represents a file delivered via Djatoka
class DjatokaImage < SourceImage
  include ActiveSupport::Benchmarkable
  # @param id [StacksIdentifier]
  # @param transformation [IIIF::Image::Transformation]
  # @param url [String] the url for the djatoka resolver
  def initialize(id:, transformation:, url:)
    @id = id
    @transformation = transformation
    @url = url
  end

  def valid?
    image_url.present?
  end

  private

  attr_reader :url

  def image_url
    djatoka_region.url
  rescue Djatoka::IiifInvalidParam
    nil
  end

  def djatoka_region
    @djatoka_region ||= with_retries(max_tries: 3, rescue: exceptions_to_retry) do
      iiif_req = Djatoka::IiifRequest.new(resolver, djatoka_path.uri)
      iiif_req.region(transformation.region)
              .size(transformation.size)
              .rotation(transformation.rotation)
              .quality(transformation.quality)
              .format(transformation.format)
              .djatoka_region
    end
  end

  def resolver
    @resolver ||= Djatoka::Resolver.new(@url)
  end

  def djatoka_path
    DjatokaPath.new(id)
  end

  def path
    @path ||= PathService.for(id)
  end

  def driver
    @driver ||= Settings.stacks.driver
  end

  def exceptions_to_retry
    [Errno::ECONNRESET, Errno::ECONNREFUSED, Net::ReadTimeout]
  end
end
