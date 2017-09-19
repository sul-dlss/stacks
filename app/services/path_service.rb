# Converts druids/file name to a file path on disk
module PathService
  # @param id [StacksIdentifier]
  def self.for(id)
    return unless id.valid?
    File.join(Settings.stacks.storage_root,
              id.druid_parts[1],
              id.druid_parts[2],
              id.druid_parts[3],
              id.druid_parts[4],
              id.file_name)
  end
end
