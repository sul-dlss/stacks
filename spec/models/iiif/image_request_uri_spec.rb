# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Iiif::ImageRequestUri do
  describe 'to_s' do
    subject { instance.to_s }
    let(:instance) do
      described_class.new(base_uri: base_uri, identifier: identifier, transformation: transformation)
    end
    let(:options) { { size: 'max', region: 'full' } }
    let(:transformation) { Iiif::OptionDecoder.decode(options) }
    let(:identifier) { 'foo' }
    let(:base_uri) { 'https://test.com/iiif/' }

    it 'produces a good uri' do
      expect(subject).to eq 'https://test.com/iiif/foo/full/max/0/default.jpg'
    end
  end
end
