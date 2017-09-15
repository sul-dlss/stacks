##
# Represents a file on disk in stacks. A StacksFile may be downloaded and
# may be the file that backs a StacksImage or StacksMediaStream
class StacksFile
  include ActiveModel::Model
  include StacksRights

  attr_accessor :id, :current_ability, :download

  def exist?
    path && File.exist?(path)
  end

  def mtime
    @mtime ||= File.mtime(path) if exist?
  end

  def etag
    mtime.to_i if mtime
  end

  def path
    @path ||= begin
      PathService.for(id)
    end
  end
end
