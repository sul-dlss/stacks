# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Projection do
  let(:image) { StacksImage.new(stacks_file: instance_double(StacksFile)) }
  let(:instance) { described_class.new(image, transformation) }
  let(:transformation) { IIIF::Image::OptionDecoder.decode(options) }
  let(:http_client) { instance_double(HTTP::Client) }

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
    subject(:dimensions) { instance.send(:tile_dimensions) }

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
          ability.tap { |x| allow(x).to receive(:can?).with(:download, dimensions).and_return(true) }
        end
        let(:restricted_ability) do
          ability.tap { |x| allow(x).to receive(:can?).with(:download, dimensions).and_return(false) }
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
      let(:image) { RestrictedImage.new(stacks_file: instance_double(StacksFile)) }

      context "full region" do
        let(:options) { { size: 'max', region: 'full' } }

        it 'limits users to thumbnail sizes' do
          expect(dimensions).to eq IIIF::Image::Dimension.new(width: 400, height: 400)
        end
      end

      context "best fit size" do
        let(:options) { { size: '!800,800', region: 'full' } }

        it 'limits users to thumbnail sizes' do
          expect(dimensions).to eq IIIF::Image::Dimension.new(width: 400, height: 400)
        end
      end

      context "specified region" do
        let(:options) { { size: 'max', region: '0,0,800,600' } }

        it 'limits users to a maximum tiles size' do
          expect(dimensions).to eq IIIF::Image::Dimension.new(width: 512, height: 512)
        end
      end
    end
  end

  describe '#response' do
    let(:druid) { 'nr349ct7889' }
    let(:file_name) { 'image.jp2' }
    let(:cocina) { Cocina.new(Factories.cocina_with_file) }

    context 'for an image' do
      subject(:projection) { described_class.new(image, transformation) }

      before do
        allow(HTTP).to receive_message_chain(:timeout, :headers)
          .and_return(http_client)
        allow(http_client).to receive(:get).and_return(instance_double(HTTP::Response, body: nil))
      end

      let(:image) { StacksImage.new(stacks_file: StacksFile.new(file_name:, cocina:)) }

      context "full region" do
        let(:options) { { size: 'max', region: 'full' } }

        it 'allows the user to see the full-resolution image' do
          projection.response
          expect(http_client).to have_received(:get).with(%r{/full/max/0/default.jpg})
        end
      end

      context "best fit size" do
        let(:options) { { size: '!850,700', region: 'full' } }

        it 'returns original size when requested dimensions are larger' do
          projection.response
          expect(http_client).to have_received(:get).with(%r{/full/!800,600/0/default.jpg})
        end
      end
    end

    context 'for a restricted image' do
      subject(:projection) { described_class.new(image, transformation) }

      before do
        allow(HTTP).to receive_message_chain(:timeout, :headers)
          .and_return(http_client)
        allow(http_client).to receive(:get).and_return(double(body: nil))
      end

      let(:image) { RestrictedImage.new(stacks_file: StacksFile.new(file_name:, cocina:)) }

      context "full region" do
        let(:options) { { size: 'max', region: 'full' } }

        it 'limits users to a thumbnail' do
          projection.response
          expect(http_client).to have_received(:get).with(%r{/full/!400,400/0/default.jpg})
        end
      end

      context "smaller-than-a-thumbnail size" do
        let(:options) { { size: '!100,100', region: 'full' } }

        it 'limits users to a thumbnail' do
          projection.response
          expect(http_client).to have_received(:get).with(%r{/full/!100,100/0/default.jpg})
        end
      end

      context "best fit size" do
        let(:options) { { size: '!800,880', region: 'full' } }

        it 'limits users to a thumbnail' do
          projection.response
          expect(http_client).to have_received(:get).with(%r{/full/!400,400/0/default.jpg})
        end
      end

      context "square region" do
        let(:options) { { size: '100,100', region: 'square' } }

        it 'limits users to a thumbnail' do
          projection.response
          expect(http_client).to have_received(:get).with(%r{/square/100,100/0/default.jpg})
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

      it { is_expected.to eq IIIF::Image::Dimension.new(width: 800, height: 600) }
    end

    context 'for square' do
      let(:options) { { size: 'full', region: 'square' } }

      it { is_expected.to eq IIIF::Image::Dimension.new(width: 600, height: 600) }
    end

    context 'for an explicit region' do
      let(:options) { { size: 'full', region: '0,1,2,3' } }

      it { is_expected.to eq IIIF::Image::Dimension.new(width: 2, height: 3) }
    end

    context 'for an region that contains negative values' do
      let(:options) { { size: 'full', region: '-22832,-22832,22832,22832' } }

      it 'raises an error' do
        expect { instance.region_dimensions }.to raise_error IIIF::Image::InvalidAttributeError
      end
    end
  end

  describe '#valid?' do
    subject { instance.valid? }

    let(:options) { { size: 'max', region: 'full' } }
    let(:image) { StacksImage.new(stacks_file: file) }

    before do
      allow(IiifImage).to receive(:new).and_return(source_image)
    end

    context 'when file exists and transformation is valid' do
      let(:file) { instance_double(StacksFile) }
      let(:source_image) { instance_double(IiifImage, valid?: true) }

      it { is_expected.to be true }
    end

    context 'when file exists but transformation is not valid' do
      let(:file) { instance_double(StacksFile) }
      let(:source_image) { instance_double(IiifImage, valid?: false) }

      it { is_expected.to be false }
    end
  end

  describe '#use_original_size?' do
    subject(:use_original) { described_class.new(image, transformation).send(:use_original_size?) }

    let(:image) { StacksImage.new(stacks_file: instance_double(StacksFile)) }

    context 'when percentage region is requested' do
      let(:options) { { size: 'full', region: 'pct:3.0,3.0,77.0,77.0' } }

      it { is_expected.to be false }
    end

    context 'when dimensions smaller than original size are requested' do
      let(:options) { { size: '!460,460', region: 'full' } }

      it { is_expected.to be false }
    end

    context 'when dimensions larger than original size are requested' do
      let(:options) { { size: '!900,900', region: 'full' } }

      it { is_expected.to be true }
    end
  end
end
