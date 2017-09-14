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
    let(:instance) { described_class.new }
    it { is_expected.to be_instance_of DjatokaInfoService }
  end

  describe '#info' do
    subject { instance.info }

    let(:info_service) { instance_double(DjatokaInfoService, fetch: {}) }

    before do
      allow(instance).to receive(:info_service).and_return(info_service)
    end

    it "adds tile size to the djatoka response" do
      subject
      expect(info_service).to have_received(:fetch).with(1024)
    end
  end

  describe 'profile' do
    subject { instance.profile }

    it { is_expected.to eq 'http://iiif.io/api/image/2/level1' }
  end

  describe '#thumbnail?' do
    subject { StacksImage.new(region: 'full') }

    before do
      allow(subject).to receive_messages(image_width: 800, image_height: 600)
    end

    it 'must be smaller than 400px long edge' do
      expect(subject.tap { |x| x.size = '400,400' }).to be_a_thumbnail
      expect(subject.tap { |x| x.size = '400,' }).to be_a_thumbnail

      # too big
      expect(subject.tap { |x| x.size = '401,400' }).not_to be_a_thumbnail

      # still too big
      expect(subject.tap { |x| x.size = '401,' }).not_to be_a_thumbnail

      # calculated long edge is 533px
      expect(subject.tap { |x| x.size = ',400' }).not_to be_a_thumbnail
    end

    it 'must be a full region request' do
      expect(StacksImage.new(region: '0,0,1,1')).not_to be_a_thumbnail
    end
  end

  describe '#tile?' do
    it 'must specify a region' do
      expect(subject.tap { |x| x.region = '0,0,1,1'; x.size = '256,256' }).to be_a_tile
      expect(subject.tap { |x| x.region = 'full'; x.size = '256,256' }).not_to be_a_tile
    end

    it 'must be smaller than 512px long edge' do
      expect(subject.tap { |x| x.region = '0,0,256,256'; x.size = '256,256' }).to be_a_tile
      expect(subject.tap { |x| x.region = '0,0,256,256'; x.size = '256,' }).to be_a_tile
      expect(subject.tap { |x| x.region = '0,0,256,256'; x.size = ',256' }).to be_a_tile

      expect(subject.tap { |x| x.region = '0,0,1,1'; x.size = '513,513' }).not_to be_a_tile
      expect(subject.tap { |x| x.region = '0,0,800,600'; x.size = ',513' }).not_to be_a_tile
    end
  end

  describe '#tile_dimensions' do
    it 'handles explicit sizes' do
      expect(subject.tap { |x| x.size = '257,257' }.tile_dimensions).to eq [257, 257]
    end

    it 'calculates implied dimensions' do
      expect(subject.tap { |x| x.region = '0,0,800,600'; x.size = '256,' }.tile_dimensions).to eq [256, 192]
      expect(subject.tap { |x| x.region = '0,0,800,600'; x.size = ',192' }.tile_dimensions).to eq [256, 192]
    end

    it 'handles full dimensions' do
      expect(subject.tap { |x| x.region = '0,0,800,600'; x.size = 'full' }.tile_dimensions).to eq [800, 600]
    end

    context 'for requests with "max" size' do
      let(:ability) { instance_double(Ability) }
      let(:permissive_ability) do
        ability.tap { |x| allow(x).to receive(:can?).with(:download, subject).and_return(true) }
      end
      let(:restricted_ability) do
        ability.tap { |x| allow(x).to receive(:can?).with(:download, subject).and_return(false) }
      end

      it 'returns the full image for unrestricted images' do
        subject.region = '0,0,800,600'
        subject.size = 'max'
        expect(subject.tile_dimensions).to eq [800, 600]
      end
    end

    it 'handles percentages' do
      expect(subject.tap { |x| x.region = '0,0,800,600'; x.size = 'pct:50' }.tile_dimensions).to eq [400, 300]
    end
  end

  describe '#restricted' do
    subject { image.restricted }
    let(:image) do
      described_class.new(attributes)
    end

    let(:attributes) do
      { region: '0,0,800,600',
        size: 'pct:50',
        id: '99999',
        file_name: 'foo',
        canonical_url: 'http://example.com/',
        quality: 'default',
        rotation: '0' }
    end

    it 'passes all the parameters' do
      expect(subject.region).to eq attributes[:region]
      expect(subject.size).to eq attributes[:size]
      expect(subject.id).to eq attributes[:id]
      expect(subject.file_name).to eq attributes[:file_name]
      expect(subject.canonical_url).to eq attributes[:canonical_url]
      expect(subject.quality).to eq attributes[:quality]
      expect(subject.rotation).to eq attributes[:rotation]
    end
  end

  describe '#region_dimensions' do
    it 'uses the image dimensions' do
      expect(subject.tap { |x| x.region = 'full' }.region_dimensions).to eq [800, 600]
    end

    it 'calculates percentages of the full image' do
      expect(subject.tap { |x| x.region = 'pct:50' }.region_dimensions).to eq [400, 300]
      expect(subject.tap { |x| x.region = 'pct:200' }.region_dimensions).to eq [1600, 1200]
    end

    it 'handles explicit region requests' do
      expect(subject.tap { |x| x.region = '0,1,2,3' }.region_dimensions).to eq [2, 3]
    end
  end

  describe '#valid?' do
    subject(:instance) { described_class.new(id: 'ab012cd3456', file_name: 'def') }
    subject { instance.valid? }

    context 'with good parameters' do
      before do
        instance.quality = 'default'
        instance.region = 'full'
        instance.size = 'full'
        instance.format = 'jpg'
        instance.rotation = '0'
      end
      it { is_expected.to be true }
    end

    context 'when the IIIF parameters are invalid' do
      before do
        instance.quality = 'native'
      end
      it { is_expected.to be false }
    end
  end
end
