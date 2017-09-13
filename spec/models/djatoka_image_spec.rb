# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DjatokaImage do
  subject(:instance) do
    described_class.new(id: id,
                        file_name: 'def',
                        transformation: nil)
  end

  let(:id) { 'ab012cd3456' }

  describe '#path' do
    subject(:path) { instance.send(:path) }

    it 'is a pairtree path to the jp2' do
      expect(path).to eq "#{Settings.stacks.storage_root}/ab/012/cd/3456/def.jp2"
    end

    context 'with a malformed druid' do
      let(:id) { 'abcdef' }
      it { is_expected.to be_nil }
    end
  end
end
