# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Projection do
  let(:image) { StacksImage.new }
  let(:instance) { described_class.new(image, transformation) }

  before do
    allow(image).to receive_messages(image_width: 800, image_height: 600)
  end

  describe '#thumbnail?' do
    subject { instance.thumbnail? }

    context "when equal to 400 on both edges" do
      let(:transformation) { Iiif::Transformation.new(size: '400,400', region: 'full') }

      it { is_expected.to be true }
    end

    context "when equal to 400 on height" do
      let(:transformation) { Iiif::Transformation.new(size: '400,', region: 'full') }

      it { is_expected.to be true }
    end

    context "when bigger than 400 on one edges" do
      let(:transformation) { Iiif::Transformation.new(size: '401,400', region: 'full') }

      it { is_expected.to be false }
    end

    context "when bigger than to 400 on height" do
      let(:transformation) { Iiif::Transformation.new(size: '401,', region: 'full') }

      it { is_expected.to be false }
    end

    context "when scaled short edge is bigger than to 400" do
      # calculated long edge is 533px
      let(:transformation) { Iiif::Transformation.new(size: ',400', region: 'full') }

      it { is_expected.to be false }
    end

    context "when the transformation doesn't select the full region" do
      let(:transformation) { Iiif::Transformation.new(region: '0,0,1,1', size: 'full') }

      it { is_expected.to be false }
    end
  end

  describe '#tile?' do
    let(:transformation) { Iiif::Transformation.new(size: 'full', region: 'full') }
    subject { instance.tile? }

    context 'when an absolute region is specified' do
      let(:transformation) { Iiif::Transformation.new(size: 'full', region: '0,0,1,1') }
      it { is_expected.to be true }
    end

    context 'when a full region is specified' do
      let(:transformation) { Iiif::Transformation.new(size: 'full', region: 'full') }
      it { is_expected.to be_falsey }
    end

    context "when it is smaller than 512px on long edge scaled width & height" do
      let(:transformation) { Iiif::Transformation.new(size: '256,256', region: '0,0,256,256') }
      it { is_expected.to be true }
    end

    context "when it is smaller than 512px on long edge scaled height" do
      let(:transformation) { Iiif::Transformation.new(size: '256,', region: '0,0,256,256') }
      it { is_expected.to be true }
    end

    context "when it is smaller than 512px on long edge scaled height" do
      let(:transformation) { Iiif::Transformation.new(size: ',256', region: '0,0,256,256') }
      it { is_expected.to be true }
    end

    context "when it is larger than 512px on long edge scaled width & height" do
      let(:transformation) { Iiif::Transformation.new(size: '513,513', region: '0,0,1,1') }
      it { is_expected.to be false }
    end

    context "when it is larger than 512px on long edge scaled width" do
      let(:transformation) { Iiif::Transformation.new(size: ',513', region: '0,0,800,600') }
      it { is_expected.to be false }
    end
  end

  describe '#region_dimensions' do
    subject { instance.region_dimensions }
    context 'for a full region' do
      let(:transformation) { Iiif::Transformation.new(size: 'full', region: 'full') }

      it 'uses the image dimensions' do
        expect(subject).to eq [800, 600]
      end
    end

    context 'for a percentage scale down' do
      let(:transformation) { Iiif::Transformation.new(size: 'full', region: 'pct:50') }

      it 'calculates percentages of the full image' do
        expect(subject).to eq [400, 300]
      end
    end

    context 'for a percentage scale up' do
      let(:transformation) { Iiif::Transformation.new(size: 'full', region: 'pct:200') }

      it 'calculates percentages of the full image' do
        expect(subject).to eq [1600, 1200]
      end
    end

    context 'for an explicit region' do
      let(:transformation) { Iiif::Transformation.new(size: 'full', region: '0,1,2,3') }

      it 'handles explicit region requests' do
        expect(subject).to eq [2, 3]
      end
    end
  end
end
