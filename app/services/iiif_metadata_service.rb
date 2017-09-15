# Fetch metadata from the remote IIIF server
class IiifMetadataService < MetadataService
  # @param image_id [StacksIdentifier]
  # @param canonical_url [String]
  # @param base_uri [String] base path to the IIIF server
  def initialize(image_id:, canonical_url:, base_uri:)
    id = RemoteIiifIdentifier.convert(image_id)
    @url = Iiif::URI.new(identifier: id, base_uri: base_uri).to_s
    @canonical_url = canonical_url
  end

  # @param _tile_size [Integer] unused
  # @return [Hash] a data structure representing the IIIF info response
  def fetch(_tile_size)
    json
  end

  def image_width
    json.fetch('width')
  end

  def image_height
    json.fetch('height')
  end

  private

  # @return [String] the IIIF info response
  def retrieve
    # puts "Fetching #{@url}"
    conn = HTTP.get(@url)
    raise "There was a problem fetchin #{@url}. Server returned #{conn.code}" unless conn.code == 200
    conn.body
  end

  def json
    @json ||= JSON.parse retrieve
  end
end
