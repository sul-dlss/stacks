# frozen_string_literal: true

# Represents a remote Iiif endpoint
class IiifImage
  include ActiveSupport::Benchmarkable

  # @params stacks_file [StacksFile]
  # @params transformation [IIIF::Image::Transformation]
  # @params base_uri [String]
  # @params api_version [Integer] the major version of the IIIF Image API the image server speaks
  def initialize(stacks_file:, transformation:, base_uri: Settings.imageserver.base_uri, api_version: 2)
    @stacks_file = stacks_file
    @transformation = transformation
    @base_uri = base_uri
    @api_version = api_version
  end

  delegate :valid?, to: :image_uri

  # Get the image data from the remote server
  # @return [IO]
  def response
    @response ||= retrieve
  end

  private

  def image_uri
    @image_uri ||= IIIF::Image::URI.new(base_uri: @base_uri, identifier: stacks_file.cantaloupe_identifier,
                                        transformation: server_transformation)
  end

  # IIIF Image API 3 removed the "full" size in favor of "max"
  # @return [IIIF::Image::Transformation] the transformation in the image server's dialect
  def server_transformation
    return transformation unless @api_version == 3 && transformation.size.is_a?(IIIF::Image::Size::Full)

    IIIF::Image::Transformation.new(region: transformation.region, size: IIIF::Image::Size::Max.new,
                                    rotation: transformation.rotation, quality: transformation.quality,
                                    format: transformation.format)
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
