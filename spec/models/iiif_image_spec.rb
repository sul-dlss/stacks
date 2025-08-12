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
end
