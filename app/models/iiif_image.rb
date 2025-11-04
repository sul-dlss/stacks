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
    @base_uri = base_uri
  end

  delegate :valid?, to: :image_uri

  # Get the image data from the remote server
  # @return [IO]
  def response
    @response ||= retrieve
  end

  private

  def image_uri
    @image_uri ||= IIIF::Image::URI.new(base_uri: @base_uri, identifier: stacks_file.cantaloupe_identifier, transformation:)
  end

  def image_url
    image_uri.to_s
  end

  def retrieve
    with_retries max_tries: 3, rescue: [HTTP::ConnectionError] do
      benchmark "Fetch #{image_url}" do
        HTTP.timeout(connect: 15, read_timeout: 5.minutes)
            .headers(user_agent: "#{HTTP::Request::USER_AGENT} (#{Settings.user_agent})")
            .get(image_url)
      end
    end
  end

  attr_reader :transformation, :stacks_file

  delegate :logger, to: Rails
end
