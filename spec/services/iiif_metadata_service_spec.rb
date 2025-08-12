# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifMetadataService do
  let(:base_uri) { 'https://sul-imageserver-uat.stanford.edu/cantaloupe/iiif/2/' } # 'image-server-path'
  let(:druid) { 'nr349ct7889' }
  let(:file_name) { 'image.jp2' }
  let(:stacks_file) { StacksFile.new(file_name:, cocina: Cocina.new(Factories.legacy_cocina_with_file)) }
  let(:service) { described_class.new(stacks_file:, canonical_url: 'foo', base_uri:) }
  let(:http_client) { instance_double(HTTP::Client) }

  context "When a valid JSON response is received" do
    let(:body) do
      '{"@id":"https://sul-imageserver-uat.stanford.edu/cantaloupe/iiif/2/' \
        "#{image_server_path(druid, file_name)}\"," \
        '"width":3832,' \
        '"height":2552,' \
        '"tiles":[{"width":1000,"height":1000,"scaleFactors":[1,2,4,8]}],' \
        '"sizes":[{"width":1916,"height":1276}]}'
    end
    let(:response) { instance_double(HTTP::Response, code: 200, body:) }

    before do
      allow(HTTP).to receive_message_chain(:timeout, :headers, :use).and_return(http_client)
      allow(http_client).to receive(:get)
        .with("https://sul-imageserver-uat.stanford.edu/cantaloupe/iiif/2/#{image_server_path(druid, file_name)}/info.json")
        .and_return(response)
    end

    describe "#fetch" do
      subject(:json) { service.fetch(256) }

      it "returns the json" do
        expect(json['@id']).to eq 'foo'
        expect(json['width']).to eq 3832
        expect(json.fetch('tiles').first.fetch('width')).to eq 256
        expect(json.fetch('sizes').last.fetch('width')).to eq 3832
      end
    end

    describe '#image_width' do
      subject { service.image_width }

      it { is_expected.to eq 3832 }
    end

    describe '#image_height' do
      subject { service.image_height }

      it { is_expected.to eq 2552 }
    end
  end

  context "When an invalid JSON response is received" do
    let(:empty_json) { '' }
    let(:bad_response) { instance_double(HTTP::Response, code: 200, body: empty_json) }

    before do
      allow(HTTP).to receive_message_chain(:timeout, :headers, :use)
        .and_return(http_client)
      allow(http_client).to receive(:get)
        .with("https://sul-imageserver-uat.stanford.edu/cantaloupe/iiif/2/#{image_server_path(druid, file_name)}/info.json")
        .and_return(bad_response)
    end

    describe "#fetch" do
      it "raises Stacks::UnexpectedMetadataResponseError" do
        expect { service.fetch(256) }.to raise_error Stacks::UnexpectedMetadataResponseError
      end
    end
  end
end
