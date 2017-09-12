require 'rails_helper'

RSpec.describe RestrictedImage do
  let(:instance) { described_class.new }

  describe '#info' do
    subject { instance.info }

    before do
      instance.define_singleton_method :djatoka_info do |&block|
        opts = OpenStruct.new
        block.call(opts)
        opts.to_h
      end
    end

    it "adds tile size to the djatoka response" do
      expect(subject[:tile_height]).to eq 256
      expect(subject[:tile_width]).to eq 256
    end
  end

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
