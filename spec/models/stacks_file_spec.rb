require 'rails_helper'

RSpec.describe StacksFile do
  describe '#path' do
    subject { instance.path }

    let(:identifier) { StacksIdentifier.new(druid: 'druid:ab012cd3456', file_name: 'def.pdf') }
    let(:instance) { described_class.new(id: identifier) }

    it 'is the druid tree path to the file' do
      expect(subject).to eq "#{Settings.stacks.storage_root}/ab/012/cd/3456/def.pdf"
    end

    context 'with a malformed druid' do
      let(:identifier) { StacksIdentifier.new(druid: 'abcdef', file_name: 'def.pdf') }

      it { is_expected.to be_nil }
    end

    context 'with a missing file name' do
      let(:identifier) { StacksIdentifier.new('abcdef%2F') }

      it { is_expected.to be_nil }
    end
  end
end
