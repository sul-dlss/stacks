# frozen_string_literal: true

##
# RightsMetadata interpretation
class StacksRights
  attr_reader :cocina_file, :cocina

  # @param [String] file_name
  # @param [Cocina] cocina
  def initialize(file_name:, cocina:)
    @cocina = cocina
    @cocina_file = cocina.find_file(file_name)
  end

  delegate :embargo_release_date, :thumbnail_file, to: :cocina

  def maybe_downloadable?
    %w[world stanford].include?(rights.download)
  end

  def stanford_restricted?
    rights.view == 'stanford'
  end

  def no_download?
    rights.download == 'none'
  end

  def world_viewable?
    rights.view == 'world'
  end

  # Returns true if a given file has any location restrictions.
  #   Falls back to the object-level behavior if none at file level.
  def restricted_by_location?
    rights.view == 'location-based' || rights.download == 'location-based'
  end

  def embargoed?
    embargo_release_date && Time.parse(embargo_release_date).getlocal > Time.now.getlocal
  end

  # Based on implementation of ThumbnailService in DSA
  def object_thumbnail?
    thumbnail_file == cocina_file
  end

  def rights
    @rights ||= CocinaRights.new(cocina_file['access'])
  end

  delegate :location, to: :rights
end
