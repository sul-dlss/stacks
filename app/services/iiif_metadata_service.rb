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

  # Get the metadata from the remote server and rewrite the tile size if required.
  # @param tile_size [Integer,NilClass] force the tile size to this unless it's nil
  # @return [Hash] a data structure representing the IIIF info response
  def fetch(tile_size)
    return json unless tile_size
    json.tap do |updated|
      tiledef = updated.fetch('tiles').first
      tiledef['height'] = tile_size
      tiledef['width'] = tile_size
    end
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
    raise "There was a problem fetching #{@url}. Server returned #{conn.code}" unless conn.code == 200
    conn.body
  end

  def json
    @json ||= begin
                JSON.parse(retrieve).tap do |data|
                  data['@id'] = @canonical_url
                end
              end
  end
end
