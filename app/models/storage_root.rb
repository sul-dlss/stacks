# frozen_string_literal: true

# A directory that holds Stacks files
class StorageRoot
  DRUID_PARTS_PATTERN = /\A([b-df-hjkmnp-tv-z]{2})([0-9]{3})([b-df-hjkmnp-tv-z]{2})([0-9]{4})\z/i

  # @param [String] file_name
  # @param [Cocina] cocina
  def initialize(file_name:, cocina:)
    @druid = cocina.druid
    @md5 = cocina.find_file_md5(file_name)
  end

  def relative_path
    File.join(treeified_id, druid, 'content', @md5)
  end

  private

  attr_reader :druid

  def druid_parts
    druid.match(DRUID_PARTS_PATTERN)
  end

  def treeified_id
    File.join(druid_parts[1..4])
  end
end
