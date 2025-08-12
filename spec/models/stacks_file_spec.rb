# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StacksFile do
  let(:file_name) { 'image.jp2' }
  let(:cocina) { Cocina.new(public_json) }
  let(:instance) { described_class.new(file_name:, cocina:) }
  let(:path) { storage_root.absolute_path }
  let(:storage_root) { StorageRoot.new(cocina:, file_name:) }
  let(:public_json) { Factories.cocina_with_file }

  context 'with a missing file name' do
    let(:file_name) { nil }

    it 'raises an error' do
      expect { instance }.to raise_error ActiveModel::ValidationError
    end
  end

  describe '#path' do
    it 'is the druid tree path to the file' do
      expect(instance.path).to eq(path)
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
