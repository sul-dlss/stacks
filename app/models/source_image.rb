# @abstract Represents a source of an image.
class SourceImage
  def initialize(id:, file_name:, transformation:); end

  # @return [IO]
  def response
    benchmark "Fetch #{uri}" do
      # HTTP::Response#body does response streaming
      HTTP.get(uri).body
    end
  end

  def exist?; end

  def valid?; end

  def etag; end

  def mtime; end

  private

  delegate :logger, to: Rails
end
