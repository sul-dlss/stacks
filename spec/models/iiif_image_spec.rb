# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifImage do
  let(:base_uri) { 'https://imageserver.example.com/cantaloupe/iiif/2/' }
  let(:identifier) { StacksIdentifier.new(druid: 'st808xq5141', file_name: 'st808xq5141_00_0001.jp2') }
  let(:transformation) { Iiif::Transformation.new(size: 'full', region: 'full') }
  let(:instance) do
    described_class.new(base_uri: base_uri,
                        id: identifier,
                        transformation: transformation)
  end

  describe "#remote_id" do
    subject { instance.send(:remote_id) }
    it { is_expected.to eq 'st%2F808%2Fxq%2F5141%2Fst808xq5141_00_0001.jp2' }
  end

  describe "#valid?" do
    subject { instance.valid? }
    context 'with good parameters' do
      let(:transformation) do
        Iiif::Transformation.new(size: 'full', region: 'full', quality: 'default', rotation: '0', format: 'jpg')
      end

      it { is_expected.to be true }
    end

    context 'when the IIIF parameters are invalid' do
      let(:transformation) do
        Iiif::Transformation.new(quality: 'native', region: 'full', size: 'full')
      end

      it { is_expected.to be false }
    end
  end
end
