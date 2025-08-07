# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ApprovedLocation do
  subject { described_class.new(locatable).locations }

  context "when the locatable object's IP address does exist in the configuration" do
    let(:locatable) { instance_double(User, ip_address: 'ip.address1') }

    it { is_expected.to eq %w[location1 location2] }
  end

  context "when the locatable object's IP address does not exist in the configuration" do
    let(:locatable) { instance_double(User, ip_address: 'not.a.configured.ip') }

    it { is_expected.to be_empty }
  end
end
