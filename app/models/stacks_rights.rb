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
    if use_json?
      %w[world stanford].include?(cocina_rights.download)
    else
      rights.world_unrestricted_file?(file_name) ||
        rights.stanford_only_unrestricted_file?(file_name)
    end
  end

  def stanford_restricted?
    if use_json?
      cocina_rights.view == 'stanford'
    else
      value, _rule = rights.stanford_only_rights_for_file file_name

      value
    end
  end

  # Returns true if a given file has any location restrictions.
  #   Falls back to the object-level behavior if none at file level.
  def restricted_by_location?
    if use_json?
      cocina_rights.view == 'location-based' || cocina_rights.download == 'location-based'
    else
      rights.restricted_by_location?(file_name)
    end
  end

  def embargoed?
    use_json? ? cocina_embargo? : rights.embargoed?
  end

  def embargo_release_date
    use_json? ? cocina_embargo_release_date : rights.embargo_release_date
  end

  def cocina_embargo?
    cocina_embargo_release_date && Time.parse(cocina_embargo_release_date).getlocal > Time.now.getlocal
  end

  def cocina_embargo_release_date
    @cocina_embargo_release_date ||= public_json.dig('access', 'embargo', 'releaseDate')
  end

  def object_thumbnail?
    use_json? ? cocina_thumbnail? : xml_thumbnail?
  end

  def xml_thumbnail?
    doc = Nokogiri::XML.parse(public_xml)

    thumb_element = doc.xpath('//thumb')

    if thumb_element.any?
      thumb_element.text == "#{id}/#{file_name}"
    else
      doc.xpath("//file[@id=\"#{file_name}\"]/../@sequence").text == '1'
    end
  end

  # Based on implementation of ThumbnailService in DSA
  def cocina_thumbnail?
    thumbnail_file = public_json.dig('structural', 'contains')
                                .lazy.flat_map { |file_set| file_set.dig('structural', 'contains') }
                                .find { |file| file['hasMimeType'] == THUMBNAIL_MIME_TYPE }
    thumbnail_file == cocina_file
  end

  def use_json?
    Settings.features.cocina
  end

  def rights
    use_json? ? cocina_rights : dor_auth_rights
  end

  def dor_auth_rights
    @dor_auth_rights ||= Dor::RightsAuth.parse(rights_xml)
  end

  def cocina_rights
    @cocina_rights ||= CocinaRights.new(cocina_file['access'])
  end

  def location
    use_json? ? cocina_rights.location : dor_auth_rights.obj_lvl.location.keys.first
  end

  private

  def cocina_file
    @cocina_file ||= find_file
  end

  def find_file
    public_json.dig('structural', 'contains')
               .lazy.flat_map { |file_set| file_set.dig('structural', 'contains') }
               .find { |file| file['filename'] == file_name } || raise(ActionController::MissingFile, "File not found '#{file_name}'")
  end

  def public_json
    @public_json ||= Purl.public_json(id)
  end

  def rights_xml
    public_xml
  end

  def public_xml
    @public_xml ||= Purl.public_xml(id)
  end
end
