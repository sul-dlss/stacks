require 'rails_helper'

RSpec.describe RestrictedImage do
  let(:instance) { described_class.new }

  describe '#profile' do
    subject { instance.profile }

    it { is_expected.to eq ['http://iiif.io/api/image/2/level1', { 'maxWidth' => 400 }] }
  end

  describe '#tile_dimensions' do
    subject { instance.tile_dimensions }

    before do
      instance.size = 'max'
    end

    context "full region" do
      before do
        instance.region = 'full'
      end

      it 'limits users to thumbnail sizes' do
        expect(subject).to eq [400, 400]
      end
    end

    context "specified region" do
      before do
        instance.region = '0,0,800,600'
      end

      it 'limits users to a maximum tiles size' do
        expect(subject).to eq [512, 512]
      end
    end
  end
end
