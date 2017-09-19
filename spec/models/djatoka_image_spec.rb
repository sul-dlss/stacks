# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DjatokaImage do
  subject(:instance) do
    described_class.new(id: identifier,
                        transformation: transformation,
                        url: 'foo')
  end

  let(:druid) { 'ab012cd3456' }
  let(:identifier) { StacksIdentifier.new(druid: druid, file_name: 'def') }
  let(:transformation) { nil }

  describe '#path' do
    subject(:path) { instance.send(:path) }

    it 'is a pairtree path to the jp2' do
      expect(path).to eq "#{Settings.stacks.storage_root}/ab/012/cd/3456/def.jp2"
    end

    context 'with a malformed druid' do
      let(:druid) { 'abcdef' }
      it { is_expected.to be_nil }
    end
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
