# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina do
  before do
    Rails.cache.clear
  end

  describe '.expire' do
    let(:cache) { ActiveSupport::Cache::MemoryStore.new }
    let(:druid) { 'bc123df4567' }

    def public_json(version)
      { status: 200, body: { 'externalIdentifier' => "druid:#{druid}", 'version' => version }.to_json }
    end

    before do
      allow(Rails).to receive(:cache).and_return(cache)
      stub_request(:get, "https://purl.stanford.edu/#{druid}.json").to_return(public_json(4), public_json(5))
      stub_request(:get, "https://purl.stanford.edu/#{druid}/version/5.json").to_return(public_json(5), public_json(6))
    end

    it 'makes the next find fetch the head version from purl again' do
      expect(described_class.find(druid).data['version']).to eq 4
      expect(described_class.find(druid).data['version']).to eq 4 # cached

      described_class.expire(druid)

      expect(described_class.find(druid).data['version']).to eq 5
    end

    it 'leaves cached versions alone unless asked to expire one' do
      expect(described_class.find(druid, '5').data['version']).to eq 5

      described_class.expire(druid)
      expect(described_class.find(druid, '5').data['version']).to eq 5 # still cached

      described_class.expire(druid, version: 5)
      expect(described_class.find(druid, '5').data['version']).to eq 6
    end
  end

  describe '#files' do
    let(:json) do
      {
        'externalIdentifier' => 'abc',
        'structural' => {
          'contains' => [
            {
              'structural' => {
                'contains' => [
                  {
                    'filename' => '26855.jp2',
                    'access' => {
                      'view' => 'world',
                      'download' => 'world'
                    }
                  }
                ]
              }
            },
            {
              'structural' => {
                'contains' => [
                  {
                    'filename' => '123.jp2',
                    'access' => {
                      'view' => 'world',
                      'download' => 'world'
                    }
                  }
                ]
              }
            }
          ]
        }
      }.to_json
    end

    context 'when requesting the head version' do
      before do
        stub_request(:get, "https://purl.stanford.edu/abc.json")
          .to_return(status: 200, body: json)
      end

      it 'gets all the files for a resource' do
        actual = described_class.find('abc').files.map { |file| "#{file.id}/#{file.file_name}" }

        expect(actual).to contain_exactly('abc/26855.jp2', 'abc/123.jp2')
      end
    end

    context 'when requesting a specific version' do
      before do
        stub_request(:get, "https://purl.stanford.edu/abc/version/2.json")
          .to_return(status: 200, body: json)
      end

      it 'gets all the files for a resource' do
        actual = described_class.find('abc', '2').files.map { |file| "#{file.id}/#{file.file_name}" }

        expect(actual).to contain_exactly('abc/26855.jp2', 'abc/123.jp2')
      end
    end

    context 'when the object has no files' do
      let(:json) do
        {
          'externalIdentifier' => 'abc',
          'structural' => {
            'contains' => []
          }
        }.to_json
      end

      before do
        stub_request(:get, "https://purl.stanford.edu/abc.json")
          .to_return(status: 200, body: json)
      end

      it 'returns no files' do
        expect(described_class.find('abc').files.to_a).to be_empty
      end
    end
  end

  describe '#modified' do
    it 'returns the time the object was modified' do
      expect(described_class.new(Factories.cocina_with_file).modified).to eq Time.zone.parse('2026-03-18T21:24:52Z')
    end

    it 'returns nil when the object has no modified time' do
      expect(described_class.new(Factories.cocina).modified).to be_nil
    end
  end
end
