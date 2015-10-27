require 'rails_helper'

describe IiifTokenController do
  describe '#create' do
    subject do
      get :create, format: :js
    end

    let(:user) { nil }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    context 'HTML format' do
      subject do
        get :create, format: :html
      end

      it 'redirects to JSON' do
        expect(subject).to redirect_to format: :js
      end
    end

    context 'with a user' do
      let(:user) { User.new id: 'xyz' }

      it 'returns the token response' do
        expect(subject.status).to eq 200

        data = JSON.parse(subject.body)
        expect(data['accessToken']).not_to be_blank
        expect(data['tokenType']).to eq 'Bearer'
        expect(data['expiresIn']).to be > 0
      end
    end

    context 'without a user' do
      it 'returns the error response' do
        expect(subject.status).to eq 401

        data = JSON.parse(subject.body)
        expect(data['error']).to eq 'missingCredentials'
      end
    end
  end
end
