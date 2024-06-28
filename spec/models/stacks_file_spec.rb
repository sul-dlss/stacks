# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StacksFile do
  let(:druid) { 'nr349ct7889' }
  let(:file_name) { 'image.jp2' }
  let(:instance) { described_class.new(id: druid, file_name:, cocina: Cocina.new({})) }
  let(:path) { storage_root.absolute_path }
  let(:storage_root) { StorageRoot.new(druid:, file_name:) }

  describe '#path' do
    subject { instance.path }

    it 'is the druid tree path to the file' do
      expect(subject).to eq(path)
    end

    context 'with a malformed druid' do
      let(:druid) { 'abcdef' }

      it { is_expected.to be_nil }
    end

    context 'with a missing file name' do
      let(:file_name) { nil }

      it { is_expected.to be_nil }
    end
  end

  describe '#readable?' do
    subject { instance.readable? }

    before do
      allow(File).to receive(:world_readable?).with(path).and_return(permissions)
    end

    context 'with a readable file' do
      let(:permissions) { 420 }

      it { is_expected.to eq 420 }
    end

    context 'with an unreadable file' do
      let(:permissions) { nil }

      it { is_expected.to be_nil }
    end
  end
end
