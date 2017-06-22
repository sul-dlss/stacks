# PURL API service
class Purl
  include ActiveSupport::Benchmarkable

  def self.instance
    @purl ||= new
  end

  class << self
    delegate :public_xml, to: :instance
  end

  def public_xml(druid, etag)
    Rails.cache.fetch("purl/#{druid}-#{etag}/public_xml", expires_in: 10.minutes) do
      benchmark "Fetching public xml for #{druid}" do
        Faraday.get(public_xml_url(druid)).body
      end
    end
  end

  private

  def public_xml_url(druid)
    Settings.purl.url + "#{druid}.xml"
  end

  def logger
    Rails.logger
  end
end
