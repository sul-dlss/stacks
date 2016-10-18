require 'rails_helper'

##
# A stub metadata class that mimics
# some of the underlying IIIF logic
# in the Djatoka gem for testing purposes
class StubMetadataObject
  # Turn block assignments into a hash
  def info
    opts = OpenStruct.new
    yield(opts) if block_given?
    opts.to_h
  end

  def maybe_downloadable?
    false
  end
end

describe IiifController do
  before do
    allow_any_instance_of(StacksImage).to receive(:valid?).and_return(true)
    allow_any_instance_of(StacksImage).to receive(:exist?).and_return(true)
    allow_any_instance_of(DjatokaMetadata).to receive(:as_json).and_return(
      '@context' => [],
      'tiles' => [{ 'width' => 1024, 'height' => 1024 }]
    )
    stub_rights_xml(world_readable_rights_xml)
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
    subject { get :metadata, params: { identifier: 'nr349ct7889%2Fnr349ct7889_00_0001' } }

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

  describe '#image_info' do
    let(:stub_metadata_object) { StubMetadataObject.new }
    let(:image_info) { controller.send(:image_info) }
    before do
      allow(controller).to receive(:current_image).and_return(stub_metadata_object)
    end

    # This is kind of a round-about way to test this,
    # but the actual logic that we're depending on
    # here is buried in the djatoka gem
    describe 'height/width' do
      context 'when the image is downloadable' do
        before do
          allow(controller).to receive(:can?).with(:download, stub_metadata_object).and_return(true)
        end

        it 'the tile height/width is 1024' do
          expect(image_info[:tile_height]).to eq 1024
          expect(image_info[:tile_width]).to eq 1024
        end
      end

      context 'when the image is not downloadable' do
        it 'the tile height/width is 256' do
          expect(image_info[:tile_height]).to eq 256
          expect(image_info[:tile_width]).to eq 256
        end
      end
    end
  end
end
