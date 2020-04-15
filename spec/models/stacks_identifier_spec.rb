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

  describe '#treeified_path' do
    subject { instance.treeified_path }
    it { is_expected.to eq 'nr/349/ct/7889/nr349ct7889_00_0001.jp2' }
  end

  context 'with some optional attributes' do
    let(:instance) { described_class.new identifier }
    let(:identifier) { 'nr349ct7889%2Fnr349ct7889_00_0001%2F!attr!%2Fversion=2'}

    it 'parses out the right data' do
      expect(instance.druid).to eq 'nr349ct7889'
      expect(instance.file_name_without_ext).to eq 'nr349ct7889_00_0001'
      expect(instance.options['version']).to eq '2'
    end

    it 'reserializes to the original value' do
      expect(instance.to_s).to eq identifier
    end
  end
end
