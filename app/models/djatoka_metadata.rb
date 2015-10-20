require 'djatoka'
require 'nokogiri'

class DjatokaMetadata
  include ActiveSupport::Benchmarkable

  THUMBNAIL_EDGE = 400 # 400-pixel long edge dimension
  SQUARE_EDGE    = 100

  PRECAST_SIZES = %w(full xlarge large medium small)
  AVAILABLE_MIME_TYPES = %w(image/jpeg image/png image/gif image/bmp)

  IIIF_PROFILE_URL = 'http://library.stanford.edu/iiif/image-api/1.1/compliance.html'
  IIIF_CONTEXT_URL = 'http://library.stanford.edu/iiif/image-api/1.1/context.json'

  # instance variables
  attr_reader :metadata, :canonical_url

  def self.find(canonical_url, file_path)
    DjatokaMetadata.new(canonical_url, file_path)
  end

  # constructor
  def initialize(canonical_url, stacks_file_path)
    @canonical_url = canonical_url
    @stacks_file_path = stacks_file_path
  end

  # Builds an Hash containing the response to a IIIF Image Information Request
  # @return [String] The serialized JSON-LD of a Image Information Request
  def as_json(&block)
    JSON.parse(metadata.to_iiif_json(canonical_url, &block))
  end

  # returns the maximum width
  def max_width
    metadata.width.to_i
  end

  # returns the maximum height
  def max_height
    metadata.height.to_i
  end

  # return the image metadata
  def metadata
    @metadata ||= Rails.cache.fetch("djatoka/metadata/#{@stacks_file_path}", expires_in: 10.minutes) do
      benchmark "Fetching djatoka metadata for #{@stacks_file_path}" do
        resolver = Djatoka::Resolver.new(Settings.stacks.djatoka_url)
        resolver.metadata(@stacks_file_path).perform
      end
    end
  end

  private

  def logger
    Rails.logger
  end
end
