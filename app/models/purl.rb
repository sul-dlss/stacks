# frozen_string_literal: true

# PURL API service
class Purl
  include ActiveSupport::Benchmarkable

  class Exception < ::RuntimeError; end

  def self.instance
    @instance ||= new
  end

  class << self
    delegate :public_xml, :public_json, :files, to: :instance
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

  def files(druid, &)
    return to_enum(:files, druid) unless block_given?

    Settings.features.cocina ? files_from_json(druid, &) : files_from_xml(druid, &)
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
        file = StacksFile.new(id: druid, file_name: attr['id'])
        yield file
      end
    end
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
