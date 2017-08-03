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

  def restricted_by_location?
    false
  end

  def maybe_downloadable?
    false
  end

  def stanford_restricted?
    stanford_only_rights.first
  end

  def stanford_only_rights
    [false, nil]
  end

  def location_rights(_location)
    [false, nil]
  end

  def restricted_locations
    []
  end
end

describe IiifController do
  before do
    allow_any_instance_of(StacksImage).to receive(:valid?).and_return(true)
    allow_any_instance_of(StacksImage).to receive(:exist?).and_return(true)
    allow_any_instance_of(StacksImage).to receive(:response).and_return(StringIO.new)
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
    before do
      allow(controller).to receive(:can?).with(:download, an_instance_of(StacksImage)).and_return(true)
    end

    subject { get :metadata, params: { identifier: 'nr349ct7889%2Fnr349ct7889_00_0001' } }

    it 'provides iiif info.json responses' do
      subject
      expect(controller.content_type).to eq 'application/json'
      expect(controller.response_body.first).to match('@context')
    end

    it 'asserts level1 IIIF compliance' do
      subject
      info = JSON.parse(controller.response_body.first)
      expect(info['profile']).to eq 'http://iiif.io/api/image/2/level1'
      expect(controller.headers['Link']).to eq '<http://iiif.io/api/image/2/level1.json>;rel="profile"'
    end

    it 'includes a recommended tile size' do
      subject
      info = JSON.parse(controller.response_body.first)
      expect(info['tiles'].first).to include 'width' => 1024, 'height' => 1024
    end

    context 'image is not downloadable' do
      before do
        allow(controller).to receive(:can?).with(:download, an_instance_of(StacksImage)).and_return(false)
      end

      it 'asserts level1 IIIF compliance, and augments the default profile with maxWidth' do
        subject
        info = JSON.parse(controller.response_body.first)
        expect(info['profile']).to eq ['http://iiif.io/api/image/2/level1', { 'maxWidth' => 400 }]
        expect(controller.headers['Link']).to eq '<http://iiif.io/api/image/2/level1.json>;rel="profile"'
      end
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
          allow(controller.send(:anonymous_ability)).to receive(:can?)
            .with(:download, stub_metadata_object).and_return(true)
        end

        it 'the tile height/width is 1024' do
          expect(image_info[:tile_height]).to eq 1024
          expect(image_info[:tile_width]).to eq 1024
        end

        it 'omits the authentication service' do
          expect(image_info['service']).not_to be_present
        end
      end

      context 'when the image is not downloadable' do
        let(:auth_service) { image_info['service'] }

        before do
          allow(stub_metadata_object).to receive(:stanford_only_rights).and_return([true, nil])
        end

        it 'the tile height/width is 256' do
          expect(image_info[:tile_height]).to eq 256
          expect(image_info[:tile_width]).to eq 256
        end

        it 'advertises an authentication service' do
          expect(auth_service).to be_present
          expect(auth_service['profile']).to eq 'http://iiif.io/api/auth/1/login'
          expect(auth_service['@id']).to eq iiif_auth_api_url

          expect(auth_service['service'].first['profile']).to eq 'http://iiif.io/api/auth/1/token'
          expect(auth_service['service'].first['@id']).to eq iiif_token_api_url
          expect(auth_service['label']).to eq 'Log in to access all available features.'
          expect(auth_service['confirmLabel']).to eq 'Login'
          expect(auth_service['failureHeader']).to eq 'Unable to authenticate'
          expect(auth_service['failureDescription'])
            .to eq 'The authentication service cannot be reached. If your brow'\
            'ser is configured to block pop-up windows, try allowing pop-up wi'\
            'ndows for this site before attempting to log in again.'
        end

        it 'advertises a logout service' do
          logout_service = auth_service['service'].find { |x| x['profile'] == 'http://iiif.io/api/auth/1/logout' }
          expect(logout_service['profile']).to eq 'http://iiif.io/api/auth/1/logout'
          expect(logout_service['@id']).to eq logout_url
          expect(logout_service['label']).to eq 'Logout'
        end
      end

      context 'when the image is location-restricted' do
        let(:location_service) { image_info['service'] }

        before do
          allow(stub_metadata_object).to receive(:restricted_by_location?).and_return(true)
          allow(stub_metadata_object).to receive(:restricted_locations).and_return([:spec])
        end

        it 'advertises an authentication service' do
          location_restriction_msg = 'Restricted content cannot be accessed from your location'
          expect(location_service).to be_present
          expect(location_service['profile']).to eq 'http://iiif.io/api/auth/1/external'
          expect(location_service['label']).to eq 'External Authentication Required'
          expect(location_service['failureHeader']).to eq 'Restricted Material'
          expect(location_service['failureDescription']).to eq location_restriction_msg
          expect(location_service['service'].first['profile']).to eq 'http://iiif.io/api/auth/1/token'
          expect(location_service['service'].first['@id']).to eq iiif_token_api_url
        end
      end

      context 'when the item has location and stanford-only rights' do
        before do
          allow(stub_metadata_object).to receive(:stanford_only_rights).and_return([true, nil])
          allow(stub_metadata_object).to receive(:restricted_by_location?).and_return(true)
          allow(stub_metadata_object).to receive(:restricted_locations).and_return([:spec])
        end

        it 'advertises support for both login and external authentication' do
          expect(image_info['service']).to be_present
          expect(image_info['service'].length).to eq 2
          expect(image_info['service'].map { |x| x['profile'] }).to match_array [
            'http://iiif.io/api/auth/1/login',
            'http://iiif.io/api/auth/1/external'
          ]
        end
      end
    end
  end
end
