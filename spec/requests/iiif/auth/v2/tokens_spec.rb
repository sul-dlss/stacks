# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'IIIF auth v2 tokens' do
  let(:user) { User.new(anonymous_locatable_user: true) }

  before do
    allow_any_instance_of(Iiif::Auth::V2::TokenController).to receive(:current_user).and_return(user)
  end

  describe '#create' do
    let(:user) { User.new id: 'xyz', webauth_user: true }

    before do
      get '/iiif/auth/v2/token?origin=http://example.edu/&messageId=1'
    end

    it 'posts the response' do
      expect(response.response_code).to eq 200
      expect(response.headers['X-Frame-Options']).to eq ''
      payload = JSON.parse(/({.*\})/.match(response.body)[1])
      expect(payload).to include(
        { "@context" => "http://iiif.io/api/auth/2/context.json",
          "type" => "AuthAccessToken2", 'accessToken' => be_present,
          'messageId' => '1', 'expiresIn' => 3600 }
      )
    end

    context 'when there is an error' do
      let(:user) { User.new id: 'xyz', webauth_user: false }

      it 'posts the response' do
        expect(response.response_code).to eq 200
        expect(response.headers['X-Frame-Options']).to eq ''
        payload = JSON.parse(/({.*\})/.match(response.body)[1])
        expect(payload).to eq(
          { "@context" => "http://iiif.io/api/auth/2/context.json",
            "type" => "AuthAccessTokenError2",
            'profile' => 'missingAspect',
            'messageId' => '1',
            'heading' => 'Missing credentials' }
        )
      end
    end

    context 'when the origin parameter is missing' do
      it 'returns a 400 error' do
        get '/iiif/auth/v2/token?messageId=1'
        expect(response).to have_http_status(:bad_request)
      end
    end
  end
end
