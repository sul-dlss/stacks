# frozen_string_literal: true

# Fetch metadata from the remote IIIF server
class IiifMetadataService < MetadataService
  # @param image_id [StacksIdentifier]
  # @param canonical_url [String]
  # @param base_uri [String] base path to the IIIF server
  def initialize(image_id:, canonical_url:, base_uri:)
    id = RemoteIiifIdentifier.convert(image_id)
    @url = IIIF::Image::URI.new(identifier: id, base_uri: base_uri).to_s
    @canonical_url = canonical_url
  end

  # Get the metadata from the remote server and rewrite the tile size if required.
  # Cantaloupe also doesn't send the full size as one of the 'sizes'
  # @param tile_size [Integer,NilClass] force the tile size to this unless it's nil
  # @return [Hash] a data structure representing the IIIF info response
  def fetch(tile_size)
    json.tap do |updated|
      if tile_size
        tiledef = updated.fetch('tiles').first
        tiledef['height'] = tile_size
        tiledef['width'] = tile_size
      end
      # Add a full size for parity with our Djatoka implmentation,
      # because Cantaloupe doesn't provide it
      updated.fetch('sizes').push('width' => updated.fetch('width'),
                                  'height' => updated.fetch('height'))
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
    with_retries max_tries: 3, rescue: [HTTP::ConnectionError] do
      conn = HTTP.get(@url)
      raise "There was a problem fetching #{@url}. Server returned #{conn.code}" unless conn.code == 200
      conn.body
    end
  end

  def json
    retrieved_json = retrieve
    @json ||= begin
                JSON.parse(retrieved_json).tap do |data|
                  data['@id'] = @canonical_url
                end
              end
  rescue JSON::ParserError => error
    raise Stacks::UnexpectedMetadataResponseError.new(@url, error, retrieved_json)
  end
end
