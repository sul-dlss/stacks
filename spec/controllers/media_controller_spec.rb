# frozen_string_literal: true

require 'rails_helper'

RSpec.describe MediaController do
  before do
    allow(Cocina).to receive(:find).and_return(Cocina.new(public_json))
  end

  let(:public_json) do
    {
      'structural' => {
        'contains' => [
          {
            'structural' => {
              'contains' => [
                {
                  'filename' => 'bb582xs1304_sl.mp4',
                  'access' => {
                    'view' => 'world',
                    'download' => 'world'
                  }
                }
              ]
            }
          }
        ]
      }
    }
  end
  let(:video) { StacksMediaStream.new(id: 'bb582xs1304', file_name: 'bb582xs1304_sl', format: 'mp4') }

  describe '#verify_token' do
    let(:id) { 'ab123cd4567' }
    let(:file_name) { 'interesting_video.mp4' }
    let(:ip_addr) { '192.168.1.100' }
    let(:token) { StacksMediaToken.new(id, file_name, ip_addr) }
    let(:encrypted_token) { token.to_encrypted_string }

    context 'mock #token_valid?' do
      it 'verifies a token when token_valid? returns true' do
        expect(controller).to receive(:token_valid?).with(encrypted_token, id, file_name, ip_addr).and_return true
        get :verify_token, params: { stacks_token: encrypted_token, id:, file_name:, user_ip: ip_addr }
        expect(response.body).to eq 'valid token'
        expect(response).to have_http_status :ok
      end

      it 'rejects a token when token_valid? returns false' do
        expect(controller).to receive(:token_valid?).with(encrypted_token, id, file_name, ip_addr).and_return false
        get :verify_token, params: { stacks_token: encrypted_token, id:, file_name:, user_ip: ip_addr }
        expect(response.body).to eq 'invalid token'
        expect(response).to have_http_status :forbidden
      end
    end

    context 'actually try to verify the token' do
      let(:valid_token) { { stacks_token: encrypted_token, id:, file_name:, user_ip: ip_addr } }
      # these tests are a bit more integration-ish, since they actually end up calling
      # StacksMediaToken.verify_encrypted_token? instead of mocking the call to MediaController#token_valid?
      it 'verifies a valid token' do
        get :verify_token, params: valid_token
        expect(response.body).to eq 'valid token'
        expect(response).to have_http_status :ok
      end

      it 'rejects a token with a corrupted encrypted token string' do
        get :verify_token, params: valid_token.merge(stacks_token: "#{encrypted_token}aaaa")
        expect(response.body).to eq 'invalid token'
        expect(response).to have_http_status :forbidden
      end

      it 'rejects a token for the wrong id' do
        get :verify_token, params: valid_token.merge(id: 'zy098xv7654')
        expect(response.body).to eq 'invalid token'
        expect(response).to have_http_status :forbidden
      end

      it 'rejects a token for the wrong file name' do
        get :verify_token, params: valid_token.merge(file_name: 'some_other_file.mp3')
        expect(response.body).to eq 'invalid token'
        expect(response).to have_http_status :forbidden
      end

      it 'rejects a token from the wrong IP address' do
        get :verify_token, params: valid_token.merge(user_ip: '192.168.1.101')
        expect(response.body).to eq 'invalid token'
        expect(response).to have_http_status :forbidden
      end

      it 'rejects a token that is too old' do
        expired_timestamp = (StacksMediaToken.max_token_age + 2.seconds).ago
        allow_any_instance_of(StacksMediaToken).to receive(:timestamp).and_return(expired_timestamp)
        get :verify_token, params: valid_token
        expect(response.body).to eq 'invalid token'
        expect(response).to have_http_status :forbidden
      end
    end
  end

  describe '#token_valid?' do
    it 'should call through to StacksMediaToken.verify_encrypted_token? and return the result' do
      expect(StacksMediaToken).to receive(:verify_encrypted_token?)
        .with('stacks_token', 'id', 'file_name', 'ip_addr').and_return(true)
      expect(controller.send(:token_valid?, 'stacks_token', 'id', 'file_name', 'ip_addr')).to be true
    end
  end

  describe '#auth_check' do
    let(:id) { 'bd786fy6312' }
    let(:file_name) { 'some_file.mp4' }

    it 'returns JSON from hash_for_auth_check' do
      test_hash = { foo: :bar }
      expect(controller).to receive(:hash_for_auth_check).and_return(test_hash)
      get :auth_check, params: { id:, file_name:, format: :js }
      body = response.parsed_body
      expect(body).to eq('foo' => 'bar')
    end

    context 'success' do
      before do
        # We could be more integration-y and instead e.g. stub_request(:get, "https://purl.stanford.edu/bd786fy6312.json").to_return(...).
        # But the StacksMediaStream code (and the metadata fetching/parsing code it uses) that'd be exercised by that approach is already
        # tested elsewhere. This approach is a bit more readable, and less brittle since it doesn't break the StacksMediaStream abstraction.
        stacks_media_stream = instance_double(StacksMediaStream, stanford_restricted?: false, restricted_by_location?: false,
                                                                 embargoed?: false, embargo_release_date: nil,
                                                                 encrypted_token: 'sekret-token')
        allow(controller).to receive_messages(can?: true, current_media: stacks_media_stream)
      end

      it 'returns json that indicates a successful auth check (including token)' do
        get :auth_check, params: { id:, file_name:, format: :js }
        body = response.parsed_body
        expect(body['status']).to eq 'success'
        expect(body['token']).to eq 'sekret-token'
      end

      it 'returns info about applicable access restrictions' do
        get :auth_check, params: { id:, file_name:, format: :js }
        body = response.parsed_body
        expect(body['access_restrictions']).to eq({
                                                    'stanford_restricted' => false,
                                                    'restricted_by_location' => false,
                                                    'embargoed' => false,
                                                    'embargo_release_date' => nil
                                                  })
      end
    end
  end
end
