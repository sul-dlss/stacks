# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StacksFile do
  let(:path) { "#{Settings.stacks.storage_root}/ab/012/cd/3456/def.pdf" }
  let(:instance) { described_class.new(id: 'ab012cd3456', file_name: 'def.pdf') }

  describe '#path' do
    subject { instance.path }

    it 'is the druid tree path to the file' do
      expect(subject).to eq "#{Settings.stacks.storage_root}/ab/012/cd/3456/def.pdf"
    end

    context 'with a malformed druid' do
      let(:instance) { described_class.new(id: 'abcdef', file_name: 'def.pdf') }

      it { is_expected.to be_nil }
    end

    context 'with a missing file name' do
      let(:instance) { described_class.new(id: 'abcdef', file_name: nil) }

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
