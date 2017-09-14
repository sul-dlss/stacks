# Converts druids/file name to a file path on disk
module PathService
  # @param id [StacksIdentifier]
  def self.for(id)
    match = id.druid.match(/^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/i)
    return unless match && id.file_name
    File.join(Settings.stacks.storage_root,
              match[1],
              match[2],
              match[3],
              match[4],
              id.file_name)
  end
end
