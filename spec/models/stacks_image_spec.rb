# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StacksImage do
  subject { instance }
  let(:instance) { described_class.new }

  before do
    allow(instance).to receive_messages(image_width: 800, image_height: 600)
  end

  describe "#info_service" do
    subject { instance.send(:info_service) }

    let(:identifier) { StacksIdentifier.new(druid: 'ab012cd3456', file_name: 'def') }
    let(:instance) { described_class.new(id: identifier) }
    it { is_expected.to be_kind_of MetadataService }
  end

  describe '#info' do
    subject { instance.info }

    let(:info_service) { instance_double(DjatokaMetadataService, fetch: {}) }

    before do
      allow(instance).to receive(:info_service).and_return(info_service)
    end

    it "gets the info from the djatoka response" do
      subject
      expect(info_service).to have_received(:fetch).with(nil)
    end
  end

  describe 'profile' do
    subject { instance.profile }
    context 'when max_pixels threshold is not reached' do
      before do
        expect(instance).to receive_messages(exceeds_threshold?: false)
      end

      it { is_expected.to eq 'http://iiif.io/api/image/2/level2' }
    end

    context 'when max_pixels threshold is reached' do
      before do
        expect(instance).to receive_messages(exceeds_threshold?: true, max_width: 1234)
      end

      it { is_expected.to eq ['http://iiif.io/api/image/2/level2', { maxWidth: 1234 }] }
    end
  end

  describe '#restricted' do
    subject { image.restricted }

    let(:image) do
      described_class.new(attributes)
    end
    let(:identifier) { StacksIdentifier.new(druid: 'ab012cd3456', file_name: 'def') }

    let(:transformation) do
      IIIF::Image::Transformation.new(
        region: '0,0,800,600',
        size: 'full',
        quality: 'default',
        rotation: '0'
      )
    end

    let(:attributes) do
      { id: identifier,
        canonical_url: 'http://example.com/',
        transformation: transformation }
    end

    it 'passes all the parameters' do
      expect(subject.transformation).to eq attributes[:transformation]
      expect(subject.id).to eq attributes[:id]
      expect(subject.canonical_url).to eq attributes[:canonical_url]
    end
  end
end
