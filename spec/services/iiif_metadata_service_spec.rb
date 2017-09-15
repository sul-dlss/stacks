# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifMetadataService do
  let(:identifier) do
    StacksIdentifier.new(druid: 'nr349ct7889', file_name: 'nr349ct7889_00_0001')
  end
  let(:base_uri) { 'https://sul-imageserver-uat.stanford.edu/cantaloupe/iiif/2/' } # 'image-server-path'
  let(:service) { described_class.new(image_id: identifier, canonical_url: 'foo', base_uri: base_uri) }
  let(:json) do
    '{"@id":"https://sul-imageserver-uat.stanford.edu/cantaloupe/iiif/2/' \
    'nr%2F349%2Fct%2F7889%2Fnr349ct7889_00_0001.jp2",' \
    '"width":3832,' \
    '"height":2552}'
  end
  let(:response) { instance_double(HTTP::Response, code: 200, body: json) }
  before do
    allow(HTTP).to receive(:get)
      .with('https://sul-imageserver-uat.stanford.edu/cantaloupe/iiif/2/nr%2F349%2Fct%2F7889%2Fnr349ct7889_00_0001.jp2/info.json')
      .and_return(response)
  end

  describe "#fetch" do
    subject { service.fetch(256) }
    it "returns the json" do
      expect(subject['@id']).to eq 'foo'
      expect(subject['width']).to eq 3832
    end
  end

  describe '#image_width' do
    subject { service.image_width }
    it "Returns the width of the image" do
      expect(subject).to eq 3832
    end
  end

  describe '#image_height' do
    subject { service.image_height }
    it "Returns the height of the image" do
      expect(subject).to eq 2552
    end
  end
end
