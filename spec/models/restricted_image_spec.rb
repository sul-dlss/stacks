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

    it { is_expected.to eq ['http://iiif.io/api/image/2/level2', { 'maxWidth' => 400 }] }
  end
end
