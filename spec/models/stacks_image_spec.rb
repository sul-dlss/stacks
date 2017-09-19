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

    it { is_expected.to eq 'http://iiif.io/api/image/2/level1' }
  end

  describe '#tile_dimensions' do
    subject { StacksImage.new(transformation: transformation) }

    context "explicit sizes" do
      let(:transformation) { Iiif::Transformation.new(size: '257,257', region: 'full') }

      it 'handles explicit sizes' do
        expect(subject.tile_dimensions).to eq [257, 257]
      end
    end

    context "height" do
      let(:transformation) { Iiif::Transformation.new(size: '256,', region: '0,0,800,600') }

      it 'calculates implied dimensions' do
        expect(subject.tile_dimensions).to eq [256, 192]
      end
    end

    context "width" do
      let(:transformation) { Iiif::Transformation.new(size: ',192', region: '0,0,800,600') }

      it 'calculates implied dimensions' do
        expect(subject.tile_dimensions).to eq [256, 192]
      end
    end

    context 'full dimensions' do
      let(:transformation) { Iiif::Transformation.new(size: 'full', region: '0,0,800,600') }

      it "calculates dimensions" do
        expect(subject.tile_dimensions).to eq [800, 600]
      end
    end

    context 'for requests with "max" size' do
      let(:ability) { instance_double(Ability) }
      let(:permissive_ability) do
        ability.tap { |x| allow(x).to receive(:can?).with(:download, subject).and_return(true) }
      end
      let(:restricted_ability) do
        ability.tap { |x| allow(x).to receive(:can?).with(:download, subject).and_return(false) }
      end
      let(:transformation) { Iiif::Transformation.new(size: 'max', region: '0,0,800,600') }

      it 'returns the full image for unrestricted images' do
        expect(subject.tile_dimensions).to eq [800, 600]
      end
    end

    context 'percentages' do
      let(:transformation) { Iiif::Transformation.new(size: 'pct:50', region: '0,0,800,600') }
      it "returns 1/2 size" do
        expect(subject.tile_dimensions).to eq [400, 300]
      end
    end
  end

  describe '#restricted' do
    subject { image.restricted }

    let(:image) do
      described_class.new(attributes)
    end
    let(:identifier) { StacksIdentifier.new(druid: 'ab012cd3456', file_name: 'def') }

    let(:transformation) do
      Iiif::Transformation.new(
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

  describe '#valid?' do
    let(:identifier) { StacksIdentifier.new(druid: 'ab012cd3456', file_name: 'def') }
    let(:instance) { described_class.new(id: identifier, transformation: nil) }
    subject { instance.valid? }

    before do
      allow(StacksImageSourceFactory).to receive(:create).and_return(source_image)
    end

    context 'when source_image exists and is valid' do
      let(:source_image) { instance_double(SourceImage, valid?: true, exist?: true) }

      it { is_expected.to be true }
    end

    context 'when source_image exists but is not valid' do
      let(:source_image) { instance_double(SourceImage, valid?: false, exist?: true) }

      it { is_expected.to be false }
    end

    context 'when source_image does not exist' do
      let(:source_image) { instance_double(SourceImage, exist?: false) }

      it { is_expected.to be false }
    end
  end
end
