require 'rails_helper'

RSpec.describe RestrictedImage do
  let(:instance) { described_class.new }

  describe '#info' do
    subject { instance.info }

    let(:info_service) { instance_double(DjatokaMetadataService, fetch: {}) }

    before do
      allow(instance).to receive(:info_service).and_return(info_service)
    end

    it "adds tile size to the djatoka response" do
      subject
      expect(info_service).to have_received(:fetch).with(256)
    end
  end

  describe '#profile' do
    subject { instance.profile }

    it { is_expected.to eq ['http://iiif.io/api/image/2/level1', { 'maxWidth' => 400 }] }
  end

  describe '#tile_dimensions' do
    subject { instance.tile_dimensions }

    let(:instance) { described_class.new(transformation: transformation) }

    context "full region" do
      let(:transformation) { Iiif::Transformation.new(size: 'max', region: 'full') }

      it 'limits users to thumbnail sizes' do
        expect(subject).to eq [400, 400]
      end
    end

    context "specified region" do
      let(:transformation) { Iiif::Transformation.new(size: 'max', region: '0,0,800,600') }

      it 'limits users to a maximum tiles size' do
        expect(subject).to eq [512, 512]
      end
    end
  end
end
