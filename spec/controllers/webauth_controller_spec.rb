# frozen_string_literal: true

require 'rails_helper'

RSpec.describe WebauthController do
  let(:user) { User.new }

  before do
    allow(controller).to receive(:current_user).and_return(user)
    request.env['REMOTE_USER'] = 'username'
    request.env['eduPersonEntitlement'] = 'a;b'
  end

  describe '#logout' do
    it 'gives directions for quitting the browser session' do
      get :logout
      expect(response).to be_successful
    end
  end

  describe '#login_file' do
    subject { get :login_file, params: params }
    let(:params) { { id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2' } }

    it 'returns the user to the file api' do
      expect(subject).to redirect_to file_url(params)
    end

    it 'stores user information in the session' do
      get :login_file, params: params
      expect(session.to_h).to include 'remote_user' => 'username', 'workgroups' => 'a;b'
    end

    context 'with a failed login' do
      subject { get :login_file, params: params }

      before do
        allow(controller).to receive(:current_user).and_return(nil)
      end

      it 'returns a 403' do
        expect(subject.status).to eq 403
      end
    end
  end

  describe '#login_iiif' do
    subject { get :login_iiif, params: params }
    let(:params) do
      {
        identifier: 'nr349ct7889%2Fnr349ct7889_00_0001',
        region: '0,640,2552,2552',
        size: '100,100',
        rotation: '0',
        quality: 'default',
        format: 'jpg'
      }
    end

    it 'stores user information in the session' do
      get :login_iiif, params: params
      expect(session.to_h).to include 'remote_user' => 'username', 'workgroups' => 'a;b'
    end

    it 'returns the user to the image' do
      expect(subject).to redirect_to iiif_url(params)
    end
  end
end
