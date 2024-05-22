# frozen_string_literal: true

##
# RightsMetadata interpretation
class StacksRights
  attr_reader :id, :file_name

  THUMBNAIL_MIME_TYPE = 'image/jp2'

  def initialize(id:, file_name:)
    @id = id
    @file_name = file_name
  end

  def maybe_downloadable?
    %w[world stanford].include?(rights.download)
  end

  def stanford_restricted?
    rights.view == 'stanford'
  end

  # Returns true if a given file has any location restrictions.
  #   Falls back to the object-level behavior if none at file level.
  def restricted_by_location?
    rights.view == 'location-based' || rights.download == 'location-based'
  end

  def embargo_release_date
    cocina_embargo_release_date
  end

  def embargoed?
    cocina_embargo_release_date && Time.parse(cocina_embargo_release_date).getlocal > Time.now.getlocal
  end

  def cocina_embargo_release_date
    @cocina_embargo_release_date ||= public_json.dig('access', 'embargo', 'releaseDate')
  end

  # Based on implementation of ThumbnailService in DSA
  def object_thumbnail?
    thumbnail_file = public_json.dig('structural', 'contains')
                                .lazy.flat_map { |file_set| file_set.dig('structural', 'contains') }
                                .find { |file| file['hasMimeType'] == THUMBNAIL_MIME_TYPE }
    thumbnail_file == cocina_file
  end

  def rights
    @rights ||= CocinaRights.new(cocina_file['access'])
  end

  delegate :location, to: :rights

  private

  def cocina_file
    @cocina_file ||= find_file
  end

  def find_file
    file_sets = public_json.dig('structural', 'contains')
    raise(ActionController::MissingFile, "File not found '#{file_name}'") unless file_sets # Trap for Collections

    file_sets.lazy.flat_map { |file_set| file_set.dig('structural', 'contains') }
             .find { |file| file['filename'] == file_name } || raise(ActionController::MissingFile, "File not found '#{file_name}'")
  end

  def public_json
    @public_json ||= Purl.public_json(id)
  end
end
