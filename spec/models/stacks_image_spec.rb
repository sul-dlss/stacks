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
        subject.current_ability = permissive_ability

        expect(subject.tile_dimensions).to eq [800, 600]
      end

      it 'limits users to thumbnail sizes for restricted images' do
        subject.region = 'full'
        subject.size = 'max'
        subject.current_ability = restricted_ability

        expect(subject.tile_dimensions).to eq [400, 400]
      end

      it 'limits users to a maximum tiles size for restricted images' do
        subject.region = '0,0,800,600'
        subject.size = 'max'
        subject.current_ability = restricted_ability

        expect(subject.tile_dimensions).to eq [512, 512]
      end
    end

    it 'handles percentages' do
      expect(subject.tap { |x| x.region = '0,0,800,600'; x.size = 'pct:50' }.tile_dimensions).to eq [400, 300]
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

  describe '#valid?' do
    subject { described_class.new(id: 'ab012cd3456', file_name: 'def') }

    it 'is valid with good parameters' do
      subject.quality = 'default'
      subject.region = 'full'
      subject.size = 'full'
      subject.format = 'jpg'
      subject.rotation = '0'
      expect(subject).to be_valid
    end

    it 'is invalid if the IIIF parameters are invalid' do
      expect(subject.tap { |x| x.quality = 'native' }).not_to be_valid
    end
  end
end
