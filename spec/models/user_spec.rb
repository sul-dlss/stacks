# frozen_string_literal: true

require 'rails_helper'

# These specs are a rather integration-y approach to testing ability.rb. Essentially
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

    context 'with a service user' do
      it 'is a stanford user' do
        expect(described_class.new(service_user: true)).to be_stanford
      end
    end
  end

  describe '.from_service_token' do
    subject(:user) { described_class.from_service_token(token) }

    context 'with a token signed by the service token secret' do
      let(:token) { JWT.encode({ sub: 'sdr-harvest' }, Settings.service_token.hmac_secret, 'HS256') }

      it 'is a service user named by the token' do
        expect(user.id).to eq 'sdr-harvest'
        expect(user).to be_a_service_user
        expect(user).to be_stanford
      end
    end

    context 'with a token signed by another secret' do
      let(:token) { JWT.encode({ sub: 'sdr-harvest' }, 'wrong-secret', 'HS256') }

      it { is_expected.to be_nil }
    end

    context 'with a IIIF access token' do
      let(:token) { described_class.new(id: 'test-user').token }

      it { is_expected.to be_nil }
    end

    context 'when no secret is configured' do
      let(:token) { JWT.encode({ sub: 'sdr-harvest' }, 'any-secret', 'HS256') }

      before { allow(Settings.service_token).to receive(:hmac_secret).and_return(nil) }

      it { is_expected.to be_nil }
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
