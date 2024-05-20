# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'IIIF auth v1 tokens' do
  let(:user) { User.new(anonymous_locatable_user: true) }

  before do
    allow_any_instance_of(Iiif::Auth::V1::TokenController).to receive(:current_user).and_return(user)
  end

  describe '#create' do
    context 'when messageId is sent (browser-based interaction)' do
      let(:user) { User.new id: 'xyz', webauth_user: true }

      before do
        get '/image/iiif/token?origin=http://example.edu/&messageId=1'
      end

      it 'wipes out the X-Frame-Options header' do
        expect(response.headers['X-Frame-Options']).to eq ''
      end

      it 'assigns the message and origin parameters' do
        expect(response.response_code).to eq 200
        expect(assigns(:origin)).to eq 'http://example.edu/'
        expect(assigns(:message)).to include messageId: '1', accessToken: be_present
      end

      context 'when the format is js' do
        before do
          get '/image/iiif/token.js?origin=http://example.edu/&messageId=1'
        end

        it 'renders HTML anyway' do
          expect(response.body).to match(/<html/)
        end
      end

      context 'when the origin parameter is missing' do
        it 'returns a 400 error' do
          get '/image/iiif/token?messageId=1'
          expect(response).to have_http_status(:bad_request)
        end
      end
    end

    describe 'JSON API interaction' do
      context 'with a user' do
        before do
          get '/image/iiif/token'
        end

        let(:user) { User.new id: 'xyz', webauth_user: true }

        it 'returns the token response' do
          expect(response).to have_http_status :ok

          data = response.parsed_body
          expect(data['accessToken']).not_to be_blank
          expect(data['tokenType']).to eq 'Bearer'
          expect(data['expiresIn']).to be > 0
        end
      end

      context 'with an anonymous user' do
        before do
          get '/image/iiif/token'
        end

        it 'returns the error response' do
          expect(response).to have_http_status :unauthorized

          expect(response.parsed_body['error']).to eq 'missingCredentials'
        end
      end
    end
  end
end
