require 'djatoka'
require 'nokogiri'

##
# Djatoka metadata response wrapper/parser
class DjatokaMetadata
  include ActiveSupport::Benchmarkable

  # instance variables
  attr_reader :canonical_url

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

  # @return [Djatoka::Metadata] the image metadata
  def metadata
    @metadata ||= Rails.cache.fetch("djatoka/metadata/#{@stacks_file_path}", expires_in: 10.minutes) do
      fetch_metadata
    end
  end

  private

  # @return [Djatoka::Metadata]
  def fetch_metadata
    with_retries(max_tries: 3, rescue: exceptions_to_retry) do
      benchmark "Fetching djatoka metadata for #{@stacks_file_path}" do
        resolver = Djatoka::Resolver.new(Settings.stacks[driver].image.attributes.url)
        resolver.metadata(@stacks_file_path).perform
      end
    end
  end

  def logger
    Rails.logger
  end

  def driver
    @driver ||= Settings.stacks.driver
  end

  def exceptions_to_retry
    [Errno::ECONNRESET, Errno::ECONNREFUSED, Net::ReadTimeout]
  end
end
