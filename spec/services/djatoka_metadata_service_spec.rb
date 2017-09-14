# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DjatokaMetadataService do
  let(:image) { StacksImage.new(id: 'nr349ct7888', file_name: 'nr349ct7889_00_0001', canonical_url: 'foo') }
  let(:service) { described_class.new image }
  let(:metadata) { instance_double(DjatokaMetadata, max_width: 999, max_height: 888) }

  before do
    allow(DjatokaMetadata).to receive(:new).and_return(metadata)
  end

  describe '#image_width' do
    subject { service.image_width }
    it "Returns the width of the image" do
      expect(subject).to eq 999
      expect(DjatokaMetadata).to have_received(:new).with('foo',
                                                          'file:///stacks/nr/349/ct/7888/nr349ct7889_00_0001.jp2')
    end
  end

  describe '#image_height' do
    subject { service.image_height }
    it "Returns the height of the image" do
      expect(subject).to eq 888
    end
  end
end
