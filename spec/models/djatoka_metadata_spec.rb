require 'rails_helper'

##
# A stub test class to model
# a Djatoka::Metadata class
class DjatokaMetadataTestClass
  def height
    '200'
  end

  def width
    '300'
  end

  def to_iiif_json(*)
    { 'the_json' => 'from_iiif' }.to_json
  end

  def perform
    self
  end
end

RSpec.describe DjatokaMetadata do
  let(:stacks_file_path) { '/stacks/file/path' }
  let(:djatoka_metadata) { DjatokaMetadataTestClass.new }

  subject { described_class.new('//canonical/url', stacks_file_path) }

  before do
    allow(Djatoka::Resolver).to receive(:new).and_return(
      double('Djatoka::Resolver', metadata: djatoka_metadata)
    )
  end

  describe '#as_json' do
    it 'parses JSON returned by #to_iiif_json and returns the serialized form' do
      expect(subject.as_json).to eq('the_json' => 'from_iiif')
    end
  end

  describe '#max_height' do
    it 'is the height from the metadata as an integer' do
      expect(subject.max_height).to be 200
    end
  end

  describe '#max_width' do
    it 'is the width from the metadata as an integer' do
      expect(subject.max_width).to be 300
    end
  end

  describe '#metadata' do
    it 'fetches the djatoka metadata from the cache' do
      expect(Rails.cache).to receive(:fetch).with(
        "djatoka/metadata/#{stacks_file_path}", expires_in: 10.minutes
      ).and_call_original

      expect(subject.metadata).to be_a(DjatokaMetadataTestClass)
    end
  end
end
