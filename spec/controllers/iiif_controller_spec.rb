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
      subject { get :show, iiif_params.merge(ignored: 'ignored', host: 'host') }
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
