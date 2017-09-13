# Resolves path on disk given id and filename
class DjatokaPath
  def initialize(id, filename)
    @id = id
    @filename = filename
  end

  def uri
    "file://#{path}"
  end

  private

  def path
    @path ||= begin
                pth = PathService.for(@id, @filename)
                pth + '.jp2' if pth
              end
  end
end
