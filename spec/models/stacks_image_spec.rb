require 'rails_helper'

describe StacksImage do
  before do
    allow(subject).to receive_messages(image_width: 800, image_height: 600)
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

  # rubocop:disable Style/Semicolon
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

    it 'handles percentages' do
      expect(subject.tap { |x| x.region = '0,0,800,600'; x.size = 'pct:50' }.tile_dimensions).to eq [400, 300]
    end
  end
  # rubocop:enable Style/Semicolon

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

  describe '#path' do
    subject { described_class.new(id: 'ab012cd3456', file_name: 'def') }

    it 'should be the pairtree path to the jp2' do
      expect(subject.path).to eq "#{Settings.stacks.storage_root}/ab/012/cd/3456/def.jp2"
    end

    context 'with a malformed druid' do
      subject { described_class.new(id: 'abcdef', file_name: 'def') }
      it 'is nil' do
        expect(subject.path).to be_nil
      end
    end
  end
end
