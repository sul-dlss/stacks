# Represents a remote Iiif endpoint
class IiifImage < SourceImage
  include ActiveSupport::Benchmarkable
  # TODO: inject base_uri
  # @params id [StacksIdentifier]
  # @params transformation [IiifTransformation]
  # @params base_uri [String]
  def initialize(id:, transformation:, base_uri:)
    @file = StacksFile.new(id: id)
    @transformation = transformation
    @base_uri = base_uri
  end

  def exist?
    # TODO call head on the url
  end

  def valid?
    url.present?
  end

  private

  attr_reader :transformation

  def uri
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
