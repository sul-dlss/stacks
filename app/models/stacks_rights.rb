# frozen_string_literal: true

##
# RightsMetadata interpretation
class StacksRights
  attr_reader :id, :file_name

  def initialize(id:, file_name:)
    @id = id
    @file_name = file_name
  end

  def maybe_downloadable?
    rights.world_unrestricted_file?(file_name) ||
      rights.stanford_only_unrestricted_file?(file_name)
  end

  def stanford_restricted?
    value, _rule = rights.stanford_only_rights_for_file file_name

    value
  end

  def cdl_restricted?
    value, _rule = rights.cdl_rights_for_file file_name

    value
  end

  # Returns true if a given file has any location restrictions.
  #   Falls back to the object-level behavior if none at file level.
  def restricted_by_location?
    rights.restricted_by_location?(file_name)
  end

  delegate :embargoed?, to: :rights

  def object_thumbnail?
    doc = Nokogiri::XML.parse(public_xml)

    thumb_element = doc.xpath('//thumb')

    if thumb_element.any?
      thumb_element.text == "#{id}/#{file_name}"
    else
      doc.xpath("//file[@id=\"#{file_name}\"]/../@sequence").text == '1'
    end
  end

  def rights
    @rights ||= Dor::RightsAuth.parse(rights_xml)
  end

  private

  def rights_xml
    public_xml
  end

  def public_xml
    @public_xml ||= Purl.public_xml(id)
  end
end
