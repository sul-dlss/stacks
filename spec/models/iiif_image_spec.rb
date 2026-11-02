# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifImage do
  let(:base_uri) { 'https://imageserver.example.com/cantaloupe/iiif/2/' }
  let(:druid) { 'nr349ct7889' }
  let(:file_name) { 'image.jp2' }
  let(:transformation) { IIIF::Image::Transformation.new(size: 'full', region: 'full') }
  let(:stacks_file) { StacksFile.new(file_name:, cocina: Cocina.new(Factories.cocina_with_file)) }
  let(:instance) { described_class.new(stacks_file:, base_uri:, transformation:) }

  describe "#valid?" do
    subject { instance.valid? }

    context 'with good parameters' do
      let(:transformation) do
        IIIF::Image::Transformation.new(size: 'full', region: 'full', quality: 'default', rotation: '0', format: 'jpg')
      end

      it { is_expected.to be true }
    end

    context 'when the IIIF parameters are invalid' do
      let(:transformation) do
        IIIF::Image::Transformation.new(quality: 'native', region: 'full', size: 'full')
      end

      it { is_expected.to be false }
    end
  end

  describe '#response' do
    let(:http_client) { instance_double(HTTP::Client, get: instance_double(HTTP::Response)) }
    let(:transformation) { IIIF::Image::OptionDecoder.decode(ActiveSupport::HashWithIndifferentAccess.new(size: 'full', region: 'full')) }

    before do
      allow(HTTP).to receive_message_chain(:timeout, :headers).and_return(http_client)
      instance.response
    end

    context 'with a IIIF Image API 2 server' do
      it 'requests the full size' do
        expect(http_client).to have_received(:get).with(%r{/full/full/0/default.jpg$})
      end
    end

    context 'with a IIIF Image API 3 server' do
      let(:base_uri) { 'https://imageserver.example.com/v3/' }
      let(:instance) { described_class.new(stacks_file:, base_uri:, transformation:, api_version: 3) }

      it 'requests the max size, because v3 removed "full"' do
        expect(http_client).to have_received(:get).with(%r{^https://imageserver.example.com/v3/.+/full/max/0/default.jpg$})
      end
    end
  end
end
