##
# Files in stacks
class StacksFile
  include ActiveModel::Model
  include ActiveSupport::Benchmarkable
  include StacksRights

  attr_accessor :id, :file_name

  def exist?
    path && File.exist?(path)
  end

  def valid?
    image_exist?
  end

  def mtime
    @mtime ||= File.mtime(path) if exist?
  end

  def etag
    mtime.to_i if mtime
  end

  def path
    @path ||= begin
      match = druid.match(/^([a-z]{2})(\d{3})([a-z]{2})(\d{4})$/i)

      File.join(Settings.stacks.storage_root, match[1], match[2], match[3], match[4], file_name) if match
    end
  end

  private

  def druid
    id.split(':').last
  end
end
