require 'rails_helper'

describe WebauthController do
  let(:user) { User.new }

  before do
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe '#login_file' do
    subject { get :login_file, id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2' }

    it 'returns the user to the file api' do
      expect(subject).to redirect_to file_url(controller.params.symbolize_keys)
    end
  end

  describe '#login_iiif' do
    subject do
      get :login_iiif, identifier: 'nr349ct7889%2Fnr349ct7889_00_0001',
                       region: '0,640,2552,2552',
                       size: '100,100',
                       rotation: '0',
                       quality: 'default',
                       format: 'jpg'
    end

    it 'returns the user to the image' do
      expect(subject).to redirect_to iiif_url(controller.params.symbolize_keys)
    end
  end

  describe 'with a failed login' do
    subject { get :login_file, id: 'xf680rd3068', file_name: 'xf680rd3068_1.jp2' }

    before do
      allow(controller).to receive(:current_user).and_return(nil)
    end

    it 'returns a 403' do
      expect(subject.status).to eq 403
    end
  end
end
