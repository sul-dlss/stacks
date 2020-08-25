# frozen_string_literal: true

require 'errors'

# Fetch metadata from the remote IIIF server
class IiifMetadataService
  attr_reader :id, :file_name, :canonical_url

  # @param id [String]
  # @param file_name [String]
  # @param canonical_url [String]
  # @param base_uri [String] base path to the IIIF server
  def initialize(id:, file_name:, canonical_url:, base_uri: Settings.imageserver.base_uri)
    identifier = CGI.escape(StacksFile.new(id: id, file_name: file_name).treeified_path)
    @url = IIIF::Image::URI.new(identifier: identifier, base_uri: base_uri).to_s
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
      handle_response(
        # Disable url normalization as an upstream bug in addressable causes issues for `+`
        # https://github.com/sporkmonger/addressable/issues/386
        HTTP.use({ normalize_uri: { normalizer: lambda(&:itself) } }).get(@url)
      )
    end
  end

  def handle_response(conn)
    case conn.code
    when 200
      conn.body
    when 503
      raise Stacks::ImageServerUnavailable, "Unable to reach image server (503 Service Unavailable) for #{@url}."
    else
      raise Stacks::RetrieveMetadataError, "There was a problem fetching #{@url}. Server returned #{conn.code}"
    end
  end

  def json
    retrieved_json = retrieve
    @json ||= begin
                JSON.parse(retrieved_json).tap do |data|
                  data['@id'] = @canonical_url
                end
              end
  rescue JSON::ParserError => e
    raise Stacks::UnexpectedMetadataResponseError, "There was a problem fetching #{@url}. #{e}: #{retrieved_json}"
  end
end
