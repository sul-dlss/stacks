# Converts druids/file name to a file path on disk
module PathService
  def self.for(druid, file_name)
    match = druid.match(/^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/i)

    File.join(Settings.stacks.storage_root, match[1], match[2], match[3], match[4], file_name) if match && file_name
  end
end
