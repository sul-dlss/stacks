# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApprovedLocation do
  subject { described_class.new(locatable) }

  context "when the locatable object's IP address does exist in the configuration" do
    let(:locatable) { double('Locatable', ip_address: 'ip.address1') }

    it 'returns the location name as a string' do
      expect(subject.locations).to eq %w[location1 location2]
    end
  end

  context "when the locatable object's IP address does not exist in the configuration" do
    let(:locatable) { double('Locatable', ip_address: 'not.a.configured.ip') }

    it 'returns an empty array' do
      expect(subject.locations).to eq []
    end
  end

  context 'when the locatable object has no IP address' do
    let(:locatable) { double('NotReallyLocatable') }

    it 'returns an empty array' do
      expect(subject.locations).to eq []
    end
  end
end
