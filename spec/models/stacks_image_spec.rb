# frozen_string_literal: true

require 'rails_helper'

RSpec.describe StacksImage do
  subject(:instance) { described_class.new(stacks_file:) }
  let(:stacks_file) { instance_double(StacksFile) }

  before do
    allow(instance).to receive_messages(image_width: 800, image_height: 600) # rubocop:disable RSpec/SubjectStub
  end

  describe "#info_service" do
    subject { instance.send(:info_service) }
    let(:stacks_file) { StacksFile.new(file_name: 'image.jp2', cocina: Cocina.new(Factories.legacy_cocina_with_file)) }
    let(:instance) { described_class.new(stacks_file:) }

    it { is_expected.to be_a IiifMetadataService }
  end

  describe '#info' do
    let(:info_service) { instance_double(IiifMetadataService, fetch: {}) }

    before do
      allow(instance).to receive(:info_service).and_return(info_service) # rubocop:disable RSpec/SubjectStub
    end

    it "gets the info from the image server response" do
      instance.info
      expect(info_service).to have_received(:fetch).with(nil)
    end
  end

  describe 'profile' do
    subject { instance.profile }

    it { is_expected.to eq ['http://iiif.io/api/image/2/level2.json'] }
  end

  describe '#restricted' do
    subject(:restricted) { image.restricted }

    let(:image) do
      described_class.new(stacks_file:,
                          canonical_url: 'http://example.com/',
                          transformation:)
    end

    let(:transformation) do
      IIIF::Image::Transformation.new(
        region: '0,0,800,600',
        size: 'full',
        quality: 'default',
        rotation: '0'
      )
    end

    it 'passes all the parameters' do
      expect(restricted.transformation).to eq transformation
      expect(restricted.stacks_file).to eq stacks_file
      expect(restricted.canonical_url).to eq 'http://example.com/'
    end
  end
end
