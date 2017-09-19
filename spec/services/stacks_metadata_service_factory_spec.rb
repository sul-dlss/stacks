# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StacksMetadataServiceFactory do
  describe '.create' do
    subject { described_class.create(image_id: image_id, canonical_url: canonical_url) }

    let(:image_id) { StacksIdentifier.new(druid: 'nr349ct7889', file_name: 'nr349ct7889_00_0001') }
    let(:canonical_url) { double }

    context 'when the driver is remote_iiif' do
      before do
        allow(Settings.stacks).to receive(:driver).and_return('remote_iiif')
      end
      it 'returns a metadata service' do
        expect(subject).to be_instance_of IiifMetadataService
      end
    end

    context 'when the driver is djatoka' do
      before do
        allow(Settings.stacks).to receive(:driver).and_return('djatoka')
      end
      it 'returns a metadata service' do
        expect(subject).to be_instance_of DjatokaMetadataService
      end
    end
  end
end
