# frozen_string_literal: true

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

    context 'with a REMOTE_USER header' do
      before do
        request.env['REMOTE_USER'] = 'my-user'
      end

      it 'supports webauth users' do
        expect(subject.id).to eq 'my-user'
        expect(subject).to be_a_webauth_user
      end

      context 'with webauth groups' do
        before { request.env['WEBAUTH_LDAPPRIVGROUP'] = 'a|b' }
        it 'supports webauth users' do
          expect(subject.ldap_groups).to match_array %w[a b]
        end
      end

      context 'with shibboleth groups' do
        before { request.env['eduPersonEntitlement'] = 'a;b' }
        it 'supports shibboleth users' do
          expect(subject.ldap_groups).to match_array %w[a b]
        end
      end
    end

    context 'with an empty REMOTE_USER header' do
      before do
        request.env['REMOTE_USER'] = ''
      end

      it { expect(subject).not_to be_a_webauth_user }
    end

    context 'with session information' do
      before do
        request.session[:remote_user] = 'my-user'
        request.session[:workgroups] = 'a;b'
      end

      it 'retrieves the remote user and workgroup information' do
        expect(subject.id).to eq 'my-user'
        expect(subject).to be_a_webauth_user
        expect(subject.ldap_groups).to match_array %w[a b]
      end
    end

    context 'with no other credentials' do
      it 'is an anonymous locatable user' do
        expect(subject).to be_an_anonymous_locatable_user
      end
    end
  end
end
