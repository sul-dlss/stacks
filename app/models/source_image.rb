# @abstract Represents a source of an image.
class SourceImage
  def initialize(id:, file_name:, transformation:); end

  # @return [IO]
  def response
    benchmark "Fetch #{image_url}" do
      # HTTP::Response#body does response streaming
      HTTP.get(image_url).body
    end
  end

  def valid?; end

  private

  attr_reader :transformation, :id

  delegate :logger, to: Rails
end
