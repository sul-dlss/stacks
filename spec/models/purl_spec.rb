# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Purl do
  before do
    Rails.cache.clear
  end

  describe '.public_xml' do
    it 'fetches the public xml' do
      allow(Faraday).to receive(:get).with('https://purl.stanford.edu/abc.xml').and_return(double(body: ''))

      described_class.public_xml('abc')

      expect(Faraday).to have_received(:get).with('https://purl.stanford.edu/abc.xml')
    end
  end
end
