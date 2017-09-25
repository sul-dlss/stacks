# @abstract Represents a source of an image.
class SourceImage
  def initialize(id:, file_name:, transformation:); end

  # Get the image data from the remote server
  # @return [IO]
  def response
    with_retries max_tries: 3, rescue: [HTTP::ConnectionError] do
      benchmark "Fetch #{image_url}" do
        # HTTP::Response#body does response streaming
        HTTP.get(image_url).body
      end
    end
  end

  def valid?; end

  private

  attr_reader :transformation, :id

  delegate :logger, to: Rails
end
