# Represents a file on disk, and it's delivery via Djatoka
class DjatokaImage < SourceImage
  include ActiveSupport::Benchmarkable
  def initialize(id:, file_name:, transformation:)
    @file = StacksFile.new(id: id, file_name: file_name)
    @transformation = transformation
  end

  # @return [IO]
  def response
    benchmark "Fetch #{url}" do
      # HTTP::Response#body does response streaming
      HTTP.get(url).body
    end
  end

  def exist?
    file.path.present?
  end

  def valid?
    url.present?
  end

  private

  attr_reader :transformation
  delegate :id, :file_name, :etag, :druid, :mtime, to: :file
  delegate :logger, to: Rails

  # @return [StacksFile] the file on disk that back this projection
  attr_reader :file

  def url
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
    @resolver ||= Djatoka::Resolver.new(Settings.stacks.djatoka_url)
  end

  def djatoka_path
    DjatokaPath.new(id, file_name)
  end

  def path
    @path ||= begin
                pth = PathService.for(id, file_name)
                pth + '.jp2' if pth
              end
  end

  def exceptions_to_retry
    [Errno::ECONNRESET, Errno::ECONNREFUSED, Net::ReadTimeout]
  end
end
