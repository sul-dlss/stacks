# frozen_string_literal: true

# Retrieves the public JSON (cocina) and extracts data from it.
class Cocina
  extend ActiveSupport::Benchmarkable

  THUMBNAIL_MIME_TYPE = 'image/jp2'

  def self.find(druid)
    data = Rails.cache.fetch("purl/#{druid}.json", expires_in: 10.minutes) do
      benchmark "Fetching public json for #{druid}" do
        response = Faraday.get(public_json_url(druid))
        raise Purl::Exception, response.status unless response.success?

        JSON.parse(response.body)
      end
    end
    new(data)
  end

  def self.public_json_url(druid)
    "#{Settings.purl.url}#{druid}.json"
  end

  def self.logger
    Rails.logger
  end

  def initialize(data)
    @data = data
  end

  attr_accessor :data

  def druid
    @druid ||= data.fetch('externalIdentifier').delete_prefix('druid:')
  end

  def find_file(file_name)
    file_sets = data.dig('structural', 'contains')
    raise(ActionController::MissingFile, "File not found '#{file_name}'") unless file_sets # Trap for Collections

    file_sets.lazy.flat_map { |file_set| file_set.dig('structural', 'contains') }
             .find { |file| file['filename'] == file_name } || raise(ActionController::MissingFile, "File not found '#{file_name}'")
  end

  def thumbnail_file
    data.dig('structural', 'contains')
        .lazy.flat_map { |file_set| file_set.dig('structural', 'contains') }
        .find { |file| file['hasMimeType'] == THUMBNAIL_MIME_TYPE }
  end

  def embargo_release_date
    data.dig('access', 'embargo', 'releaseDate')
  end

  def files(&)
    return to_enum(:files) unless block_given?

    files_from_json(&)
  end

  private

  def files_from_json
    data.dig('structural', 'contains').each do |fileset|
      fileset.dig('structural', 'contains').each do |file|
        file = StacksFile.new(file_name: file['filename'], cocina: self)
        yield file
      end
    end
  end
end
