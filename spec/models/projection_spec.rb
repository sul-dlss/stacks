# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Projection do
  let(:image) { StacksImage.new }
  let(:instance) { described_class.new(image, transformation) }
  let(:transformation) { IIIF::Image::OptionDecoder.decode(options) }

  before do
    allow(image).to receive_messages(image_width: 800, image_height: 600)
  end

  describe '.thumbnail' do
    subject(:projection) { described_class.thumbnail(image) }

    it 'is a thumbnail' do
      expect(projection).to be_a_thumbnail
    end
  end

  describe '#tile_dimensions' do
    subject { instance.send(:tile_dimensions) }

    context "for an unrestricted image" do
      context "explicit sizes" do
        let(:options) { { size: '257,257', region: 'full' } }

        it { is_expected.to eq IIIF::Image::Dimension.new(width: 257, height: 257) }
      end

      context "width" do
        let(:options) { { size: '256,', region: '0,0,800,600' } }

        it { is_expected.to eq IIIF::Image::Dimension.new(width: 256, height: 192) }
      end

      context "height" do
        let(:options) { { size: ',192', region: '0,0,800,600' } }

        it { is_expected.to eq IIIF::Image::Dimension.new(width: 256, height: 192) }
      end

      context 'full dimensions' do
        let(:options) { { size: 'full', region: '0,0,800,600' } }

        it { is_expected.to eq IIIF::Image::Dimension.new(width: 800, height: 600) }
      end

      context 'for requests with "max" size' do
        let(:ability) { instance_double(Ability) }
        let(:permissive_ability) do
          ability.tap { |x| allow(x).to receive(:can?).with(:download, subject).and_return(true) }
        end
        let(:restricted_ability) do
          ability.tap { |x| allow(x).to receive(:can?).with(:download, subject).and_return(false) }
        end
        let(:options) { { size: 'max', region: '0,0,800,600' } }

        it { is_expected.to eq IIIF::Image::Dimension.new(width: 800, height: 600) }
      end

      context 'percentages' do
        let(:options) { { size: 'pct:50', region: '0,0,800,600' } }
        it { is_expected.to eq IIIF::Image::Dimension.new(width: 400, height: 300) }
      end
    end

    context "for a restricted image" do
      let(:image) { RestrictedImage.new }

      context "full region" do
        let(:options) { { size: 'max', region: 'full' } }

        it 'limits users to thumbnail sizes' do
          expect(subject).to eq IIIF::Image::Dimension.new(width: 400, height: 400)
        end
      end

      context "best fit size" do
        let(:options) { { size: '!800,800', region: 'full' } }

        it 'limits users to thumbnail sizes' do
          expect(subject).to eq IIIF::Image::Dimension.new(width: 400, height: 400)
        end
      end

      context "specified region" do
        let(:options) { { size: 'max', region: '0,0,800,600' } }

        it 'limits users to a maximum tiles size' do
          expect(subject).to eq IIIF::Image::Dimension.new(width: 512, height: 512)
        end
      end
    end
  end

  describe '#response' do
    context 'for an image' do
      let(:id) { StacksIdentifier.new('ab123cd4567%2Fb') }
      let(:image) { StacksImage.new id: id }
      subject(:projection) { described_class.new(image, transformation) }

      context "full region" do
        let(:options) { { size: 'max', region: 'full' } }

        it 'allows the user to see the full-resolution image' do
          allow(HTTP).to receive(:get).and_return(double(body: nil))
          subject.response
          expect(HTTP).to have_received(:get).with(%r{/full/max/0/default.jpg})
        end
      end
    end

    context 'for a restricted image' do
      let(:id) { StacksIdentifier.new('ab123cd4567%2Fb') }
      let(:image) { RestrictedImage.new id: id }
      subject(:projection) { described_class.new(image, transformation) }

      context "full region" do
        let(:options) { { size: 'max', region: 'full' } }

        it 'limits users to a thumbnail' do
          allow(HTTP).to receive(:get).and_return(double(body: nil))
          subject.response
          expect(HTTP).to have_received(:get).with(%r{/full/!400,400/0/default.jpg})
        end
      end

      context "smaller-than-a-thumbnail size" do
        let(:options) { { size: '!100,100', region: 'full' } }

        it 'limits users to a thumbnail' do
          allow(HTTP).to receive(:get).and_return(double(body: nil))
          subject.response
          expect(HTTP).to have_received(:get).with(%r{/full/!100,100/0/default.jpg})
        end
      end

      context "best fit size" do
        let(:options) { { size: '!800,880', region: 'full' } }

        it 'limits users to a thumbnail' do
          allow(HTTP).to receive(:get).and_return(double(body: nil))
          subject.response
          expect(HTTP).to have_received(:get).with(%r{/full/!400,400/0/default.jpg})
        end
      end

      context "square region" do
        let(:options) { { size: '100,100', region: 'square' } }

        it 'limits users to a thumbnail' do
          allow(HTTP).to receive(:get).and_return(double(body: nil))
          subject.response
          expect(HTTP).to have_received(:get).with(%r{/square/100,100/0/default.jpg})
        end
      end
    end
  end

  describe '#thumbnail?' do
    subject { instance.thumbnail? }

    context "when equal to 400 on both edges" do
      let(:options) { { size: '400,400', region: 'full' } }

      it { is_expected.to be true }
    end

    context "when equal to 400 on width" do
      let(:options) { { size: '400,', region: 'full' } }

      it { is_expected.to be true }
    end

    context "when bigger than 400 on one edges" do
      let(:options) { { size: '401,400', region: 'full' } }

      it { is_expected.to be false }
    end

    context "when bigger than to 400 on width" do
      let(:options) { { size: '401,', region: 'full' } }

      it { is_expected.to be false }
    end

    context "when scaled short edge is bigger than to 400" do
      # calculated long edge is 533px
      let(:options) { { size: ',400', region: 'full' } }

      it { is_expected.to be false }
    end

    context "when the transformation doesn't select the full region" do
      let(:options) { { size: 'full', region: '0,0,1,1' } }

      it { is_expected.to be false }
    end
  end

  describe '#tile?' do
    subject { instance.tile? }

    context 'when an absolute region is specified' do
      let(:options) { { size: 'full', region: '0,0,1,1' } }

      it { is_expected.to be true }
    end

    context 'when a full region is specified' do
      let(:options) { { size: 'full', region: 'full' } }
      it { is_expected.to be_falsey }
    end

    context "when it is smaller than 512px on long edge scaled width & height" do
      let(:options) { { size: '256,256', region: '0,0,256,256' } }

      it { is_expected.to be true }
    end

    context "when it is smaller than 512px on long edge scaled width" do
      let(:options) { { size: '256,', region: '0,0,256,256' } }

      it { is_expected.to be true }
    end

    context "when it is smaller than 512px on long edge scaled height" do
      let(:options) { { size: ',256', region: '0,0,256,256' } }

      it { is_expected.to be true }
    end

    context "when it is larger than 512px on long edge scaled width & height" do
      let(:options) { { size: '513,513', region: '0,0,1,1' } }

      it { is_expected.to be false }
    end

    context "when it is larger than 512px on long edge scaled height" do
      let(:options) { { size: ',513', region: '0,0,800,600' } }

      it { is_expected.to be false }
    end
  end

  describe '#region_dimensions' do
    subject { instance.region_dimensions }
    context 'for a full region' do
      let(:options) { { size: 'full', region: 'full' } }

      it 'uses the image dimensions' do
        expect(subject).to eq IIIF::Image::Dimension.new(width: 800, height: 600)
      end
    end

    context 'for square' do
      let(:options) { { size: 'full', region: 'square' } }

      it 'uses the image dimensions' do
        expect(subject).to eq IIIF::Image::Dimension.new(width: 600, height: 600)
      end
    end

    context 'for an explicit region' do
      let(:options) { { size: 'full', region: '0,1,2,3' } }

      it 'handles explicit region requests' do
        expect(subject).to eq IIIF::Image::Dimension.new(width: 2, height: 3)
      end
    end

    context 'for an region that contains negative values' do
      let(:options) { { size: 'full', region: '-22832,-22832,22832,22832' } }

      it 'raises an error' do
        expect { subject }.to raise_error IIIF::Image::InvalidAttributeError
      end
    end
  end

  describe '#valid?' do
    let(:options) { { size: 'max', region: 'full' } }
    subject { instance.valid? }

    before do
      allow(StacksImageSourceFactory).to receive(:create).and_return(source_image)
      allow(StacksFile).to receive(:new).and_return(file)
    end

    context 'when file exists and transformation is valid' do
      let(:file) { instance_double(StacksFile, readable?: true) }
      let(:source_image) { instance_double(SourceImage, valid?: true) }
      it { is_expected.to be true }
    end

    context 'when file exists but transformation is not valid' do
      let(:file) { instance_double(StacksFile, readable?: true) }
      let(:source_image) { instance_double(SourceImage, valid?: false) }

      it { is_expected.to be false }
    end

    context 'when file does not exist' do
      let(:file) { instance_double(StacksFile, readable?: false) }
      let(:source_image) { instance_double(SourceImage) }

      it { is_expected.to be false }
    end
  end
end
