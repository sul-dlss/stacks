# frozen_string_literal: true

# Represents a remote Iiif endpoint
class IiifImage
  include ActiveSupport::Benchmarkable
  # @params stacks_file [StacksFile]
  # @params transformation [IIIF::Image::Transformation]
  # @params base_uri [String]
  def initialize(stacks_file:, transformation:, base_uri: Settings.imageserver.base_uri)
    @stacks_file = stacks_file
    @transformation = transformation
    debugger
    @base_uri = base_uri
  end

  delegate :valid?, to: :image_uri

  # Get the image data from the remote server
  # @return [IO]
  def response
    with_retries max_tries: 3, rescue: [HTTP::ConnectionError] do
      benchmark "Fetch #{image_url}" do
        HTTP.timeout(connect: 15, read_timeout: 5.minutes)
            .headers(user_agent: "#{HTTP::Request::USER_AGENT} (#{Settings.user_agent})")
            .use({ normalize_uri: { normalizer: lambda(&:itself) } })
            .get(image_url)
      end
    end
  end

  private

  def image_uri
    @image_uri ||= IIIF::Image::URI.new(base_uri: @base_uri, identifier: remote_id, transformation:)
  end

  def image_url
    image_uri.to_s
  end

  def remote_id
    CGI.escape(stacks_file.treeified_path)
  end

  attr_reader :transformation, :stacks_file

  delegate :logger, to: Rails
end
