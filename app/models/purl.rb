# frozen_string_literal: true

# PURL API service
class Purl
  include ActiveSupport::Benchmarkable

  class Exception < ::RuntimeError; end

  def self.instance
    @instance ||= new
  end

  class << self
    delegate :public_xml, :public_json, :files, :barcode, to: :instance
  end

  # TODO: was etag a valid key?
  def public_xml(druid)
    Rails.cache.fetch("purl/#{druid}/public_xml", expires_in: 10.minutes) do
      benchmark "Fetching public xml for #{druid}" do
        response = Faraday.get(public_xml_url(druid))
        raise Purl::Exception, response.status unless response.success?

        response.body
      end
    end
  end

  def public_json(druid)
    Rails.cache.fetch("purl/#{druid}.json", expires_in: 10.minutes) do
      benchmark "Fetching public json for #{druid}" do
        response = Faraday.get(public_json_url(druid))
        raise Purl::Exception, response.status unless response.success?

        JSON.parse(response.body)
      end
    end
  end

  def files(druid, &block)
    return to_enum(:files, druid) unless block_given?

    Settings.features.cocina ? files_from_json(druid, &block) : files_from_xml(druid, &block)
  end

  def files_from_json(druid)
    doc = public_json(druid)

    doc.dig('structural', 'contains').each do |fileset|
      fileset.dig('structural', 'contains').each do |file|
        file = StacksFile.new(id: druid, file_name: file['filename'])
        yield file
      end
    end
  end

  def files_from_xml(druid)
    doc = Nokogiri::XML.parse(public_xml(druid))

    doc.xpath('//contentMetadata/resource').each do |resource|
      resource.xpath('file|externalFile').each do |attr|
        file = StacksFile.new(id: attr['objectId'] || druid, file_name: attr['fileId'] || attr['id'])
        yield file
      end
    end
  end

  def barcode(druid)
    public_xml = Purl.public_xml(druid)
    doc = Nokogiri::XML.parse(public_xml)

    barcode = doc.xpath('//identityMetadata/otherId[@name="barcode"]')&.text
    return barcode if barcode.present?

    source_id = doc.xpath('//identityMetadata/sourceId[@source="sul"]')&.text
    source_id.sub(/^stanford_/, '') if source_id&.start_with?(/(stanford_)?36105/)
  end

  private

  def public_xml_url(druid)
    Settings.purl.url + "#{druid}.xml"
  end

  def public_json_url(druid)
    "#{Settings.purl.url}#{druid}.json"
  end

  def logger
    Rails.logger
  end
end
