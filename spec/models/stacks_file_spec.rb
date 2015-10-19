require 'rails_helper'

describe StacksFile do
  subject { described_class.new(id: 'druid:ab012cd3456', file_name: 'def.pdf') }

  describe '#path' do
    it 'should be the pairtree path to the file' do
      expect(subject.path).to eq "#{Settings.stacks.storage_root}/ab/012/cd/3456/def.pdf"
    end

    context 'with a malformed druid' do
      subject { described_class.new(id: 'abcdef', file_name: 'def.pdf') }
      it 'is nil' do
        expect(subject.path).to be_nil
      end
    end
  end
end
