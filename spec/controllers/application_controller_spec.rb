require 'rails_helper'

RSpec.describe ApplicationController do
  describe '#current_user' do
    subject { controller.send(:current_user) }

    context 'with an HTTP_AUTHORIZATION header' do
      let(:credentials) { ActionController::HttpAuthentication::Basic.encode_credentials('test-user', 'password') }

      before do
        request.env['HTTP_AUTHORIZATION'] = credentials
      end

      it 'supports basic auth users' do
        expect(subject.id).to eq 'test-user'
        expect(subject).to be_a_app_user
      end
    end

    context 'with a Bearer token' do
      let(:user) { User.new(id: 'test-user', ldap_groups: ['stanford:stanford']) }
      let(:credentials) do
        # `encode_credentials` hardcodes `Token` so make sure to test `Bearer`
        # http://iiif.io/api/auth/1.0/#the-json-access-token-response
        ActionController::HttpAuthentication::Token.encode_credentials(user.token).gsub('Token', 'Bearer')
      end

      before do
        request.env['HTTP_AUTHORIZATION'] = credentials
      end

      it 'supports bearer auth users' do
        expect(subject.id).to eq 'test-user'
        expect(subject).to be_a_token_user
        expect(subject).to be_stanford
      end
    end

    context 'with no other credentials' do
      it 'is an anonymous locatable user' do
        expect(subject).to be_an_anonymous_locatable_user
      end
    end
  end
end
