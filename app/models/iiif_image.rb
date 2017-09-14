# Represents a remote Iiif endpoint
class IiifImage < SourceImage
  include ActiveSupport::Benchmarkable
  # TODO: inject base_uri
  def initialize(id:, file_name:, transformation:, base_uri: Settings.stacks.remote_iiif.attributes.base_uri)
    @file = StacksFile.new(id: id, file_name: file_name)
    @transformation = transformation
    @base_uri = base_uri
  end

  def exist?
    # TODO call head on the url
  end

  def valid?
    image_url.present?
  end

  private

  attr_reader :transformation

  def image_url
    Iiif::URI.new(base_uri: @base_uri, identifier: id, transformation: transformation).to_s
    # TODO take the image url and swap the host & id
  end

  def id
    # TODO this will become the remote id if we strip the base path
    @id ||= begin
                pth = PathService.for(@file.id, @file.file_name)
                pth + '.jp2' if pth
                pth.sub(Settings.stacks.storage_root, '')
              end
  end
end
