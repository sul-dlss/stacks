# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StacksIdentifier do
  let(:instance) { described_class.new druid: druid, file_name: file_name }
  let(:druid) { 'nr349ct7889' }
  let(:file_name) { 'nr349ct7889_00_0001.jp2' }
  describe '#valid' do
    subject { instance.valid? }
    context 'with a valid druid' do
      it { is_expected.to be true }
    end

    context 'with an invalid druid' do
      let(:druid) { 'nr349ct788' }
      it { is_expected.to be false }
    end

    context 'without a file_name' do
      let(:file_name) { nil }
      it { is_expected.to be false }
    end
  end

  describe '#file_name_without_ext' do
    subject { instance.file_name_without_ext }
    it { is_expected.to eq 'nr349ct7889_00_0001' }
  end
end
