# Converts druids/file name to a file path on disk
module PathService
  # @param id [StacksIdentifier]
  def self.for(id)
    return unless id.valid?
    File.join(Settings.stacks.storage_root, id.treeified_path)
  end
end
