require 'rails_helper'

describe IiifController, :vcr do
  before do
    allow_any_instance_of(StacksImage).to receive(:valid?).and_return(true)
    allow_any_instance_of(StacksImage).to receive(:exist?).and_return(true)
  end

  describe '#show' do
    let(:iiif_params) do
      {
        identifier: 'nr349ct7889%2Fnr349ct7889_00_0001',
        region: '0,640,2552,2552',
        size: '100,100',
        rotation: '0',
        quality: 'default',
        format: 'jpg'
      }
    end

    subject do
      get :show, iiif_params
    end

    it 'loads the image' do
      subject
      image = controller.instance_variable_get(:@image)
      expect(image).to be_a_kind_of StacksImage
      expect(image.region).to eq '0,640,2552,2552'
      expect(image.size).to eq '100,100'
      expect(image.rotation).to eq '0'
    end

    it 'sets the content type' do
      subject
      expect(controller.content_type).to eq 'image/jpeg'
    end

    context 'for a missing image' do
      before do
        allow_any_instance_of(StacksImage).to receive(:valid?).and_return(false)
      end

      it 'returns a 404 Not Found' do
        expect(subject.status).to eq 404
      end
    end

    context 'for a restricted image' do
      before do
        allow(controller).to receive(:authorize!).and_raise CanCan::AccessDenied
      end

      context 'with an authenticated user' do
        let(:user) { User.new }

        before do
          allow(controller).to receive(:current_user).and_return(user)
        end

        it 'fails' do
          expect(subject.status).to eq 403
        end
      end

      context 'with an unauthenticated user' do
        it 'redirects to the webauth login endpoint' do
          expect(subject).to redirect_to auth_iiif_url(controller.params.symbolize_keys)
        end
      end
    end

    context 'with the download flag set' do
      subject { get :show, iiif_params.merge(download: true) }

      it 'sets the content-disposition header to attachment' do
        expect(subject.headers['Content-Disposition']).to start_with 'attachment'
      end

      it 'sets the preferred filename' do
        expect(subject.headers['Content-Disposition']).to include 'filename=nr349ct7889_00_0001.jpg'
      end
    end
  end

  describe '#metadata' do
    subject { get :metadata, identifier: 'nr349ct7889%2Fnr349ct7889_00_0001' }

    it 'provides iiif info.json responses' do
      subject
      expect(controller.content_type).to eq 'application/json'
      expect(controller.response_body.first).to match('@context')
    end

    it 'includes a recommended tile size' do
      allow(controller).to receive(:can?).and_return(true)
      subject
      info = JSON.parse(controller.response_body.first)
      expect(info['tiles'].first).to include 'width' => 1024, 'height' => 1024
    end
  end
end
