# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediaAuthenticationJson do
  let(:media) do
    instance_double(
      StacksMediaStream,
      restricted_by_location?: false,
      stanford_restricted?: false,
      embargoed?: false,
      location: 'm&m'
    )
  end
  let(:ability) { CocinaAbility.new(user) }
  let(:user) { instance_double(User, locations: [], webauth_user: false, stanford?: false) }
  subject(:json) { described_class.new(media:, user:, auth_url: '/the/auth/url', ability:).as_json }

  describe 'Location Restricted Media' do
    before do
      allow(media).to receive(:restricted_by_location?).and_return(true)
    end

    context 'When a user is not in the blessed location' do
      it 'returns JSON that indicates that the item is location restricted' do
        expect(json[:status]).to eq [:location_restricted]
      end
    end

    context 'When a user is in the blessed location' do
      before do
        allow(ability).to receive(:can?).with(:access, media).and_return(true)
      end

      it 'returns an empty hash because this class should not have been called in this context' do
        expect(json).to eq({})
      end
    end
  end

  describe 'Stanford Restricted Media' do
    before do
      allow(media).to receive(:stanford_restricted?).and_return(true)
    end

    context 'when the user is not Stanford authenticated' do
      it 'returns JSON that indicates that the item is stanford restricted' do
        expect(json[:status]).to eq [:stanford_restricted]
      end

      it 'returns login service information' do
        expect(json[:service]['@id']).to eq '/the/auth/url'
        expect(json[:service]['label']).to eq 'Stanford-affiliated? Login to play'
      end
    end

    context 'when the user is Stanford authenticated' do
      before do
        allow(user).to receive(:webauth_user).and_return(true)
      end

      it 'returns an empty hash because this class should not have been called in this context' do
        expect(json).to eq({})
      end
    end
  end

  describe 'Stanford Restricted OR Location Restricted Media' do
    before do
      allow(media).to receive_messages(restricted_by_location?: true, stanford_restricted?: true)
    end

    it 'returns JSON that indicates that the item is stanford restricted' do
      expect(json[:status]).to eq %i[stanford_restricted location_restricted]
    end

    it 'returns login service information' do
      expect(json[:service]['@id']).to eq '/the/auth/url'
      expect(json[:service]['label']).to eq 'Stanford-affiliated? Login to play'
    end
  end
end
