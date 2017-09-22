# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Iiif::OptionDecoder do
  describe 'decode' do
    subject { described_class.decode(options) }
    let(:options) { { size: 'max', region: 'full' } }
    it 'produces a valid Transformation' do
      expect(subject).to be_kind_of Iiif::Transformation
      expect(subject).to be_valid
    end
  end
end
