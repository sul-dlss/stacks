# frozen_string_literal: true

# A directory that holds Stacks files
class StorageRoot
  DRUID_PARTS_PATTERN = /\A([b-df-hjkmnp-tv-z]{2})([0-9]{3})([b-df-hjkmnp-tv-z]{2})([0-9]{4})\z/i

  # @param [String] file_name
  # @param [Cocina] cocina
  def initialize(file_name:, cocina:)
    @file_name = file_name
    @cocina = cocina
  end

  delegate :druid, to: :cocina

  delegate :absolute_path, to: :path_finder

  delegate :relative_path, to: :path_finder

  def treeified_id
    File.join(druid_parts[1..4])
  end

  private

  attr_reader :cocina, :file_name

  def path_finder
    @path_finder ||= path_finder_class.new(treeified_id:, file_name:, cocina:)
  end

  def path_finder_class
    LegacyPathFinder
  end

  def druid_parts
    @druid_parts ||= druid.match(DRUID_PARTS_PATTERN)
  end

  # Calculate file paths in the legacy Stacks structure
  class LegacyPathFinder
    def initialize(treeified_id:, file_name:, cocina:)
      @treeified_id = treeified_id
      @file_name = file_name
      @cocina = cocina
    end

    # As this is used for external service URLs (Canteloupe image server), we don't want to put content addressable path here.'
    def relative_path
      File.join(@treeified_id, @file_name)
    end

    def absolute_path
      return content_addressable_path if File.exist?(content_addressable_path)

      File.join(Settings.stacks.storage_root, relative_path)
    end

    def content_addressable_path
      @content_addressable_path ||= begin
        md5 = @cocina.find_file_md5(@file_name)
        File.join(Settings.stacks.content_addressable_storage_root, @treeified_id, @cocina.druid, 'content', md5)
      end
    end
  end
end
