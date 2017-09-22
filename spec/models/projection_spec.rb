# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Projection do
  let(:image) { StacksImage.new }
  let(:instance) { described_class.new(image, transformation) }
  let(:transformation) { Iiif::OptionDecoder.decode(options) }

  before do
    allow(image).to receive_messages(image_width: 800, image_height: 600)
  end

  describe '#tile_dimensions' do
    subject { instance.send(:tile_dimensions) }

    context "for an unrestricted image" do
      context "explicit sizes" do
        let(:options) { { size: '257,257', region: 'full' } }

        it { is_expected.to eq Iiif::Dimension.new(width: 257, height: 257) }
      end

      context "width" do
        let(:options) { { size: '256,', region: '0,0,800,600' } }

        it { is_expected.to eq Iiif::Dimension.new(width: 256, height: 192) }
      end

      context "height" do
        let(:options) { { size: ',192', region: '0,0,800,600' } }

        it { is_expected.to eq Iiif::Dimension.new(width: 256, height: 192) }
      end

      context 'full dimensions' do
        let(:options) { { size: 'full', region: '0,0,800,600' } }

        it { is_expected.to eq Iiif::Dimension.new(width: 800, height: 600) }
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

        it { is_expected.to eq Iiif::Dimension.new(width: 800, height: 600) }
      end

      context 'percentages' do
        let(:options) { { size: 'pct:50', region: '0,0,800,600' } }
        it { is_expected.to eq Iiif::Dimension.new(width: 400, height: 300) }
      end
    end

    context "for a restricted image" do
      let(:image) { RestrictedImage.new }

      context "full region" do
        let(:options) { { size: 'max', region: 'full' } }

        it 'limits users to thumbnail sizes' do
          expect(subject).to eq Iiif::Dimension.new(width: 400, height: 400)
        end
      end

      context "specified region" do
        let(:options) { { size: 'max', region: '0,0,800,600' } }

        it 'limits users to a maximum tiles size' do
          expect(subject).to eq Iiif::Dimension.new(width: 512, height: 512)
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
        expect(subject).to eq Iiif::Dimension.new(width: 800, height: 600)
      end
    end

    context 'for an explicit region' do
      let(:options) { { size: 'full', region: '0,1,2,3' } }

      it 'handles explicit region requests' do
        expect(subject).to eq Iiif::Dimension.new(width: 2, height: 3)
      end
    end

    context 'for an region that contains negative values' do
      let(:options) { { size: 'full', region: '-22832,-22832,22832,22832' } }

      it 'raises an error' do
        expect { subject }.to raise_error Iiif::InvalidAttributeError
      end
    end
  end
end
