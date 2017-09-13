# frozen_string_literal: true

# Fetch image information from Djatoka
class DjatokaInfoService < InfoService
  def fetch
    @metadata ||= djatoka_metadata.as_json
  end

  def image_width
    djatoka_metadata.max_width
  end

  def image_height
    djatoka_metadata.max_height
  end

  private

  delegate :canonical_url, to: :image

  def djatoka_metadata
    @djatoka_metadata ||= DjatokaMetadata.find(canonical_url, djatoka_path.uri)
  end

  def djatoka_path
    DjatokaPath.new(id, file_name)
  end
end
