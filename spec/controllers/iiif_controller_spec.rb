require 'rails_helper'

RSpec.describe IiifController do
  before do
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
      get :show, params: iiif_params
    end
    before do
      allow_any_instance_of(StacksImage).to receive(:valid?).and_return(true)
      allow_any_instance_of(StacksImage).to receive(:exist?).and_return(true)
      allow_any_instance_of(StacksImage).to receive(:response).and_return(StringIO.new)
    end
    it 'loads the image' do
      subject
      image = assigns(:image)
      expect(image).to be_a StacksImage
      expect(image.region).to eq '0,640,2552,2552'
      expect(image.size).to eq '100,100'
      expect(image.rotation).to eq '0'
    end

    it 'sets the content type' do
      subject
      expect(controller.content_type).to eq 'image/jpeg'
    end

    context 'additional params' do
      subject { get :show, params: iiif_params.merge(ignored: 'ignored', host: 'host') }
      it 'ignored when instantiating StacksImage' do
        subject
        expect { assigns(:image) }.not_to raise_exception
        expect(assigns(:image)).to be_a StacksImage
      end
    end

    it 'missing image returns 404 Not Found' do
      allow_any_instance_of(StacksImage).to receive(:valid?).and_return(false)
      expect(subject.status).to eq 404
    end

    context 'with the download flag set' do
      subject { get :show, params: iiif_params.merge(download: true) }

      it 'sets the content-disposition header to attachment' do
        expect(subject.headers['Content-Disposition']).to start_with 'attachment'
      end

      it 'sets the preferred filename' do
        expect(subject.headers['Content-Disposition']).to include 'filename=nr349ct7889_00_0001.jpg'
      end
    end
  end

  describe '#metadata' do
    before do
      allow(ImageInfoService).to receive(:info)
        .with(StacksImage, false, controller)
        .and_return(height: '999')
    end

    it 'provides iiif info.json responses' do
      get :metadata, params: { identifier: 'nr349ct7889%2Fnr349ct7889_00_0001', format: :json }
      expect(controller.content_type).to eq 'application/json'
      expect(controller.response_body.first).to eq "{\n  \"height\": \"999\"\n}"
      expect(controller.headers['Link']).to eq '<http://iiif.io/api/image/2/level1.json>;rel="profile"'
    end
  end
end
