# @abstract Represents a source of an image.
class SourceImage
  def initialize(id:, file_name:, transformation:); end

  # @return [IO]
  def response; end

  def exist?; end

  def valid?; end

  def etag; end

  def mtime; end
end
