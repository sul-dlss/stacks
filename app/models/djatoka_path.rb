# Resolves path on disk given id and filename
class DjatokaPath
  # @param id [StacksIdentifier]
  def initialize(id)
    @id = id
  end

  def uri
    "file://#{path}"
  end

  private

  def path
    @path ||= begin
                pth = PathService.for(@id)
                pth + '.jp2' if pth
              end
  end
end
