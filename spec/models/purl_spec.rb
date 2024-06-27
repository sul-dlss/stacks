# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Purl do
  before do
    Rails.cache.clear
  end

  describe '.files' do
    let(:json) do
      {
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

    before do
      allow(Faraday).to receive(:get).with('https://purl.stanford.edu/abc.json')
                                     .and_return(double(success?: true, body: json))
    end

    it 'gets all the files for a resource' do
      actual = described_class.files('abc').map { |file| "#{file.id}/#{file.file_name}" }

      expect(actual).to contain_exactly('abc/26855.jp2', 'abc/123.jp2')
    end
  end
end
