require 'rails_helper'

describe IiifTokenController do
  render_views

  describe '#create' do
    let(:user) { User.new(anonymous_locatable_user: true) }

    before do
      allow(controller).to receive(:current_user).and_return(user)
    end

    context 'browser-based interaction' do
      let(:user) { User.new id: 'xyz' }

      subject do
        get :create, params: { origin: 'http://example.edu/', messageId: '1' }
      end

      it 'sets the X-Frame-Options header' do
        expect(subject.headers['X-Frame-Options']).to eq 'ALLOW-FROM http://example.edu/'
      end

      it 'assigns the message and origin parameters' do
        expect(subject.response_code).to eq 200
        expect(assigns(:origin)).to eq 'http://example.edu/'
        expect(assigns(:message)).to include messageId: '1', accessToken: be_present
      end

      context 'other formats' do
        subject do
          get :create, params: { origin: 'http://example.edu/', messageId: '1', format: :js }
        end

        it 'renders HTML anyway' do
          expect(subject.body).to match(/<html/)
        end
      end

      context 'missing the origin header' do
        subject do
          get :create, params: { messageId: '1' }
        end

        it 'returns a 400 error' do
          expect { subject.response }.to raise_error ActionController::ParameterMissing
        end
      end
    end

    context 'JSON API interaction' do
      subject do
        get :create, params: { format: :js }
      end

      context 'HTML format' do
        subject do
          get :create, params: { format: :html }
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

      context 'with an anonymous user' do
        it 'returns the error response' do
          expect(subject.status).to eq 401

          data = JSON.parse(subject.body)
          expect(data['error']).to eq 'missingCredentials'
        end
      end
    end
  end
end
