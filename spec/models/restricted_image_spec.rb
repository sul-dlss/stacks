# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RestrictedImage do
  let(:instance) { described_class.new(stacks_file: instance_double(StacksImage)) }

  describe '#info' do
    let(:info_service) { instance_double(IiifMetadataService, fetch: {}) }

    before do
      allow(instance).to receive(:info_service).and_return(info_service)
      instance.info
    end

    it "adds tile size to the djatoka response" do
      expect(info_service).to have_received(:fetch).with(256)
    end
  end

  describe '#profile' do
    subject { instance.profile }

    before do
      allow(instance).to receive(:api_version).and_return(api_version)
    end

    context 'with a IIIF Image API 2 image server' do
      let(:api_version) { 2 }

      it { is_expected.to eq ['http://iiif.io/api/image/2/level2.json', { 'maxHeight' => 400, 'maxWidth' => 400 }] }
    end

    context 'with a IIIF Image API 3 image server' do
      let(:api_version) { 3 }

      it { is_expected.to eq 'level2' }
    end
  end

  describe '#size_limits' do
    it { expect(instance.size_limits).to eq('maxWidth' => 400, 'maxHeight' => 400) }
  end
end
