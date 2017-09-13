class DjatokaImage
  include ActiveModel::Model
  include ActiveSupport::Benchmarkable

  attr_accessor :path, :canonical_url, :size, :region, :rotation, :quality, :format

#  def initialize(params = {})
#    byebug
#    @path = "file://#{params[:path]}"
#  end

  # @return [Djatoka::Metadata] the image metadata
  def metadata
    @metadata ||= Rails.cache.fetch("djatoka/metadata/#{djatoka_path}", expires_in: 10.minutes) do
      fetch_metadata
    end
  end

  def display_region
    @display_region ||= fetch_region
  end

  private

  # @return [Djatoka::Metadata]
  def fetch_metadata
    with_retries(max_tries: 3, rescue: exceptions_to_retry) do
      benchmark "Fetching djatoka metadata for #{djatoka_path}" do
        ImageAdapter::Resolver.endpoint.metadata(djatoka_path).perform
      end
    end
  end

  def fetch_region
    @fetch_region ||= with_retries(max_tries: 3, rescue: exceptions_to_retry) do
      iiif_req = Djatoka::IiifRequest.new(ImageAdapter::Resolver.endpoint, djatoka_path)
      iiif_req.region(region)
              .size(size)
              .rotation(rotation)
              .quality(quality)
              .format(format)
              .djatoka_region
    end
  end

  def djatoka_path
    "file://#{path}"
  end

  def logger
    Rails.logger
  end

  def exceptions_to_retry
    [Errno::ECONNRESET, Errno::ECONNREFUSED, Net::ReadTimeout]
  end

end
