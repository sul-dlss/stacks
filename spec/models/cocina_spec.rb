# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Cocina do
  before do
    Rails.cache.clear
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
end
