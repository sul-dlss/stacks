# frozen_string_literal: true

# Fetch metadata from the remote IIIF server
class IiifMetadataService
  V3_CONTEXT = 'http://iiif.io/api/image/3/context.json'

  attr_reader :canonical_url

  # @param stacks_file [StacksFile]
  # @param canonical_url [String]
  # @param base_uri [String] base path to the IIIF server
  def initialize(stacks_file:, canonical_url:, base_uri: Settings.imageserver.base_uri)
    identifier = stacks_file.cantaloupe_identifier
    @url = IIIF::Image::URI.new(identifier:, base_uri:).to_s
    @canonical_url = canonical_url
  end

  # Get the metadata from the remote server and rewrite the tile size if required.
  # The response may be either IIIF Image API version 2 or 3, depending on the image server.
  # @param tile_size [Integer,NilClass] force the tile size to this unless it's nil
  # @return [Hash] a data structure representing the IIIF info response
  def fetch(tile_size)
    json.deep_dup.tap do |updated|
      if tile_size
        tiledef = updated.fetch('tiles').first
        tiledef['height'] = tile_size
        tiledef['width'] = tile_size
      end
      add_full_size(updated)
    end
  end

  # @return [Integer] the major version of the IIIF Image API the image server responded with
  def api_version
    Array(json['@context']).include?(V3_CONTEXT) ? 3 : 2
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
    with_retries max_tries: 3, rescue: [HTTP::ConnectionError, HTTP::TimeoutError] do
      handle_response(
        HTTP.timeout(connect: 15, read_timeout: 5.minutes)
            .headers(user_agent: "#{HTTP::Request::USER_AGENT} (#{Settings.user_agent})")
            .get(@url)
      )
    end
  end

  def handle_response(conn)
    case conn.code
    when 200
      conn.body
    when 503
      raise Stacks::ImageServerUnavailable, "Unable to reach image server (503 Service Unavailable) for #{@url}."
    when 502
      raise Stacks::ImageServerBadGateway, "Unable to reach image server (502 Bad Gateway) for #{@url}."
    else
      raise Stacks::RetrieveMetadataError, "There was a problem fetching #{@url}. Server returned #{conn.code}"
    end
  end

  def json
    @json ||= Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
      retrieved_json = retrieve
      JSON.parse(retrieved_json).tap do |data|
        # Version 3 uses 'id' rather than '@id'
        data[data.key?('id') ? 'id' : '@id'] = @canonical_url
      end
    rescue JSON::ParserError => e
      raise Stacks::UnexpectedMetadataResponseError, "There was a problem fetching #{@url}. #{e}: #{retrieved_json}"
    end
  end

  # Add a full size for parity with our Djatoka implementation,
  # because some image servers (e.g. Cantaloupe's v2 endpoint) don't provide it
  # or omit the optional 'sizes' field entirely
  def add_full_size(info)
    full = { 'width' => info.fetch('width'), 'height' => info.fetch('height') }
    sizes = info.fetch('sizes') { info['sizes'] = [] }
    sizes.push(full) unless sizes.any? { |size| size.slice('width', 'height') == full }
  end

  def cache_key
    "iiif_metadata/#{Digest::SHA256.hexdigest(@url)}"
  end
end
