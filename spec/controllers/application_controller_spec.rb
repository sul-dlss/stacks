require 'rails_helper'

describe ApplicationController do
  describe '#current_user' do
    subject { controller.send(:current_user) }
    it 'supports basic auth users' do
      request.env['HTTP_AUTHORIZATION'] = ActionController::HttpAuthentication::Basic.encode_credentials('test-user', 'password')
      expect(subject.id).to eq 'test-user'
      expect(subject).to be_a_app_user
    end

    it 'supports webauth users' do
      request.env['REMOTE_USER'] = 'my-user'
      expect(subject.id).to eq 'my-user'
      expect(subject).to be_a_webauth_user
    end
  end
end
