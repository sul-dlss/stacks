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
        expect(User.new(webauth_user: true, ldap_groups: %w(stanford:stanford))).to be_stanford
      end
    end

    context 'with just a webauth user' do
      it 'is not a stanford user' do
        expect(User.new(webauth_user: true, ldap_groups: %w(stanford:sponsored))).not_to be_stanford
      end
    end
  end

  describe '#token' do
    it 'is a value' do
      expect(subject.token).not_to be_blank
    end
  end

  describe '#location' do
    it 'is the string representation of the ApprovedLocation' do
      expect(User.new(ip_address: 'ip.address1').locations).to eq %w[location1 location2]
    end
  end

  context 'with JWT tokens' do
    subject(:user) do
      User.new(
        id: 'xyz',
        jwt_tokens: jwt_tokens.map do |payload|
          JWT.encode(payload, Settings.cdl.jwt.secret, Settings.cdl.jwt.algorithm)
        end
      )
    end

    let(:jwt_tokens) do
      [
        { jti: 'a', sub: 'xyz', exp: 1.hour.from_now.to_i }
      ]
    end

    describe '#cdl_tokens' do
      it 'decodes the JWT token' do
        payload = user.cdl_tokens.first

        expect(payload).to include jti: 'a', sub: 'xyz'
      end

      it 'embeds the original token in the payload' do
        payload = user.cdl_tokens.first

        expect(payload).to include token: user.jwt_tokens.first
      end

      context 'with an expired token' do
        let(:jwt_tokens) do
          [
            { jti: 'a', sub: 'xyz', exp: 1.hour.ago.to_i }
          ]
        end

        it 'filters expired tokens' do
          expect(user.cdl_tokens.count).to eq 0
        end
      end

      context 'with a token for another user' do
        let(:jwt_tokens) do
          [
            { jti: 'a', sub: 'abc', exp: 1.hour.from_now.to_i }
          ]
        end

        it 'filters tokens for other users' do
          expect(user.cdl_tokens.count).to eq 0
        end
      end
    end

    it 'round-trips the JWT tokens through IIIF access tokens' do
      tokenized_user = User.from_token(user.token)

      expect(tokenized_user.jwt_tokens).to eq user.jwt_tokens
    end
  end
end
