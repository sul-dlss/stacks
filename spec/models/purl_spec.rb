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
    it 'gets all the files for a resource' do
      allow(Faraday).to receive(:get).with('https://purl.stanford.edu/abc.xml').and_return(
        double(success?: true, body:
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
        )
      )

      actual = described_class.files('abc').map { |file| "#{file.id}/#{file.file_name}" }

      expect(actual).to match_array ['abc/26855.jp2', 'abc/123.jp2']
    end
  end

  describe '.barcode' do
    let(:barcoded_item_xml) do
      <<-EOXML
        <publicObject>
          <identityMetadata>
            <otherId name="barcode">12345</otherId>
          </identityMetadata>
        </publicObject>
      EOXML
    end

    let(:source_id_xml) do
      <<-EOXML
        <publicObject>
          <identityMetadata>
            <sourceId source="sul">stanford_36105110268922</sourceId>
          </identityMetadata>
        </publicObject>
      EOXML
    end

    let(:garbage_source_id_xml) do
      <<-EOXML
        <publicObject>
          <identityMetadata>
            <sourceId source="sul">someotherid</sourceId>
          </identityMetadata>
        </publicObject>
      EOXML
    end

    it 'gets the barcode from the otherId' do
      allow(described_class).to receive(:public_xml).with('druid').and_return(barcoded_item_xml)

      expect(described_class.barcode('druid')).to eq '12345'
    end

    it 'extracts a barcode from the sourceId' do
      allow(described_class).to receive(:public_xml).with('druid').and_return(source_id_xml)
      expect(described_class.barcode('druid')).to eq '36105110268922'
    end

    it 'returns nil if a barcode cannot be extracted from the sourceId' do
      allow(described_class).to receive(:public_xml).with('druid').and_return(garbage_source_id_xml)
      expect(described_class.barcode('druid')).to be_nil
    end
  end
end
