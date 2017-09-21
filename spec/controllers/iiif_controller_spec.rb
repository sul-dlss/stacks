require 'rails_helper'

RSpec.describe IiifController do
  describe '#show' do
    let(:identifier) { 'nr349ct7889%2Fnr349ct7889_00_0001' }
    let(:image_response) { StringIO.new }
    let(:projection) { instance_double(Projection) }
    let(:image) do
      instance_double(StacksImage,
                      valid?: true,
                      exist?: true,
                      response: image_response,
                      projection: projection,
                      etag: nil,
                      mtime: nil)
    end
    let(:iiif_params) do
      {
        identifier: identifier,
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
      # for the cache headers
      allow(controller.send(:anonymous_ability)).to receive(:can?).with(:read, projection).and_return(false)
      # for authorize! in #show
      allow(controller).to receive(:authorize!).with(:read, projection).and_return(true)
      # for current_image
      allow(controller).to receive(:can?).with(:download, image).and_return(true)
      allow(StacksImage).to receive(:new).and_return(image)
    end

    context 'with a bad druid' do
      let(:identifier) { 'nr349ct788%2Fnr349ct7889_00_0001' }

      it 'raises an error' do
        expect { subject }.to raise_error ActionController::RoutingError
      end
    end

    it 'loads the image' do
      subject
      expect(assigns(:image)).to eq image
      expect(StacksImage).to have_received(:new).with(
        transformation: Iiif::Transformation.new(region: "0,640,2552,2552",
                                                 size: "100,100",
                                                 rotation: "0",
                                                 quality: "default",
                                                 format: "jpg"),
        id: StacksIdentifier.new(druid: "nr349ct7889", file_name: 'nr349ct7889_00_0001.jp2'),
        canonical_url: "http://test.host/image/iiif/nr349ct7889%252Fnr349ct7889_00_0001"
      )
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
        expect(assigns(:image)).to eq image
      end
    end

    it 'missing image returns 404 Not Found' do
      allow(image).to receive(:valid?).and_return(false)
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
    let(:image) do
      instance_double(StacksImage,
                      valid?: true,
                      exist?: true,
                      etag: nil,
                      mtime: nil)
    end
    let(:anon_user) { instance_double(User) }

    before do
      # for the cache headers
      allow(controller).to receive(:anonymous_locatable_user).and_return(anon_user)
      allow(image).to receive(:accessable_by?).with(anon_user).and_return(false)
      # for info.json generation
      allow(controller.send(:anonymous_ability)).to receive(:can?).with(:download, image).and_return(false)
      # for current_image
      allow(controller).to receive(:can?).with(:download, image).and_return(true)
      # for degraded?
      allow(controller).to receive(:can?).with(:access, image).and_return(true)
      # In the metadata method itself
      allow(controller).to receive(:authorize!).with(:read_metadata, image).and_return(true)

      allow(StacksImage).to receive(:new).and_return(image)

      allow(IiifInfoService).to receive(:info)
        .with(image, false, controller)
        .and_return(height: '999')
    end

    it 'provides iiif info.json responses' do
      get :metadata, params: { identifier: 'nr349ct7889%2Fnr349ct7889_00_0001', format: :json }
      expect(controller.content_type).to eq 'application/json'
      expect(response).to be_successful
      expect(controller.response_body.first).to eq "{\n  \"height\": \"999\"\n}"
      expect(controller.headers['Link']).to eq '<http://iiif.io/api/image/2/level1.json>;rel="profile"'
    end
  end
end
