# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Purl do
  before do
    Rails.cache.clear
  end

  describe '.public_xml' do
    it 'fetches the public xml' do
      allow(Faraday).to receive(:get).with('https://purl.stanford.edu/abc.xml').and_return(
        double(body: '', success?: true)
      )

      described_class.public_xml('abc')

      expect(Faraday).to have_received(:get).with('https://purl.stanford.edu/abc.xml')
    end
  end

  describe '.files' do
    let(:xml) do
      <<-EOXML
      <publicObject id="druid:kn112rm5773" published="2018-02-05T18:34:41Z" publishVersion="dor-services/5.23.1">
        <contentMetadata objectId="kn112rm5773" type="image">
          <resource id="kn112rm5773_1" sequence="1" type="image">
            <label>Image 1</label>
            <file id="26855.jp2" mimetype="image/jp2" size="3832255">
              <imageData width="4850" height="4180"/>
            </file>
          </resource>
          <resource id="kn112rm5773_2" sequence="2" type="image">
            <label>Virtual image</label>
            <file id="123.jp2" mimetype="image/jp2" size="3832255">
              <imageData width="4850" height="4180"/>
            </file>
          </resource>
        </contentMetadata>
      </publicObject>
      EOXML
    end

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
      allow(Faraday).to receive(:get).with('https://purl.stanford.edu/abc.xml')
                                     .and_return(double(success?: true, body: xml))
      allow(Faraday).to receive(:get).with('https://purl.stanford.edu/abc.json')
                                     .and_return(double(success?: true, body: json))
    end

    it 'gets all the files for a resource' do
      actual = described_class.files('abc').map { |file| "#{file.id}/#{file.file_name}" }

      expect(actual).to contain_exactly('abc/26855.jp2', 'abc/123.jp2')
    end
  end
end
