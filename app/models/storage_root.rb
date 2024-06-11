# frozen_string_literal: true

# A directory that holds Stacks files
class StorageRoot
  DRUID_PARTS_PATTERN = /\A([b-df-hjkmnp-tv-z]{2})([0-9]{3})([b-df-hjkmnp-tv-z]{2})([0-9]{4})\z/i

  def initialize(druid:, file_name:)
    @druid = druid
    @druid_parts = druid.match(DRUID_PARTS_PATTERN)
    @file_name = file_name
  end

  def absolute_path
    return unless relative_path

    path_finder.absolute_path.to_s
  end

  def relative_path
    return unless druid_parts && file_name

    path_finder.relative_path.to_s
  end

  def treeified_id
    File.join(druid_parts[1..4])
  end

  private

  attr_reader :druid, :druid_parts, :file_name

  def path_finder
    @path_finder ||= path_finder_class.new(treeified_id:, druid:, file_name:)
  end

  def path_finder_class
    Settings.features.read_stacks_from_ocfl_root ? OcflPathFinder : LegacyPathFinder
  end

  # Calculate file paths in the legacy Stacks structure
  class LegacyPathFinder
    def initialize(treeified_id:, file_name:, druid:) # rubocop:disable Lint/UnusedMethodArgument
      @treeified_id = treeified_id
      @file_name = file_name
    end

    def relative_path
      File.join(@treeified_id, @file_name)
    end

    def absolute_path
      File.join(Settings.stacks.storage_root, relative_path)
    end
  end

  # Calculate file paths in the OCFL structure
  class OcflPathFinder
    def initialize(druid:, file_name:, treeified_id:) # rubocop:disable Lint/UnusedMethodArgument
      @druid = druid
      @file_name = file_name
    end

    def relative_path
      absolute_path.relative_path_from(Settings.stacks.ocfl_root)
    end

    def absolute_path
      ocfl_object.path(filepath: @file_name)
    end

    private

    def ocfl_object
      storage_root = OCFL::StorageRoot.new(base_directory: Settings.stacks.ocfl_root)
      storage_root.object(@druid)
    end
  end
end
