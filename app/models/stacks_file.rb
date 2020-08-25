# frozen_string_literal: true

##
# Represents a file on disk in stacks. A StacksFile may be downloaded and
# may be the file that backs a StacksImage or StacksMediaStream
class StacksFile
  include ActiveModel::Model
  include StacksRights

  attr_accessor :id, :current_ability, :download

  # Some files exist but have unreadable permissions, treat these as non-existent
  def readable?
    path && File.world_readable?(path)
  end

  def mtime
    @mtime ||= File.mtime(path) if readable?
  end

  def etag
    mtime&.to_i
  end

  def content_length
    @content_length ||= File.size(path) if readable?
  end

  def path
    @path ||= begin
      return unless id.valid?

      File.join(Settings.stacks.storage_root, id.treeified_path)
    end
  end
end
