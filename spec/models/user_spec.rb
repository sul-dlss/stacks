# frozen_string_literal: true

require 'rails_helper'

# These specs are a rather integration-y approach to testing ability.rb, since they rely
# on the dor-rights-auth parsing that actually gets used in the real world.  Essentially
# a giant truth table for the various combinations of object rights, object types, and user
# types that permission checking might deal with.  This is not a comprehensive listing of
# all possible permutations, but it should cover all the basics, and a number of representitive
# corner cases.  This is in lieu of the more unit test style of an ability_spec.rb.
RSpec.describe User do
  describe '#stanford?' do
    context 'with a webauth user in the appropriate workgroups' do
      it 'is a stanford user' do
        expect(described_class.new(webauth_user: true, ldap_groups: %w[stanford:stanford])).to be_stanford
      end
    end

    context 'with just a webauth user' do
      it 'is not a stanford user' do
        expect(described_class.new(webauth_user: true, ldap_groups: %w[stanford:sponsored])).not_to be_stanford
      end
    end
  end

  describe '#token' do
    subject { described_class.new.token }

    it { is_expected.not_to be_blank }
  end

  describe '#location' do
    it 'is the string representation of the ApprovedLocation' do
      expect(described_class.new(ip_address: 'ip.address1').locations).to eq %w[location1 location2]
    end
  end
end
