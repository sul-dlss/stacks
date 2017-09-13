# frozen_string_literal: true

# Fetch image information from Djatoka
class DjatokaInfoService < InfoService
  def fetch
    @metadata ||= djatoka_metadata.as_json
  end

  private

  delegate :canonical_url, :path, to: :image

  def djatoka_metadata
    DjatokaMetadata.find(canonical_url, djatoka_path)
  end

  def djatoka_path
    "file://#{path}"
  end
end
