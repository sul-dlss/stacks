# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DjatokaImage do
  subject(:instance) do
    described_class.new(id: identifier,
                        transformation: nil,
                        url: 'foo')
  end

  let(:druid) { 'ab012cd3456' }
  let(:identifier) { StacksIdentifier.new(druid: druid, file_name: 'def') }

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
end
