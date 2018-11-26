# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'IIIF API' do
  let(:metadata) do
    { 'height' => 2099,
      'width' => 1702,
      'tiles' => [{ 'width' => 256, "height" => 256, "scaleFactors" => [1, 2, 4, 8, 16] }] }
  end
  let(:metadata_service) do
    instance_double(MetadataService, fetch: metadata,
                                     image_width: 1702)
  end
  let(:stacks_image) do
    StacksImage.new(id: StacksIdentifier.new(druid: 'nr349ct7889', file_name: 'nr349ct7889_00_0001.jp2'))
  end
  let(:file_source) do
    instance_double(StacksFile, readable?: true,
                                etag: 'etag',
                                mtime: Time.zone.now)
  end

  before do
    stub_rights_xml(world_readable_rights_xml)

    # stubbing Rails.cache.fetch is required because you can't dump a singleton (double)
    # which is what happens when writing to the cache.
    allow(Rails.cache).to receive(:fetch).and_yield
    allow(StacksImage).to receive(:new).and_return(stacks_image)
    allow(stacks_image).to receive(:file_source).and_return(file_source)
    allow(StacksMetadataServiceFactory).to receive(:create).and_return(metadata_service)
  end

  it 'redirects base uri requests to the info.json document' do
    get '/image/iiif/abc'

    expect(response).to redirect_to('/image/iiif/abc/info.json')
    expect(response.status).to eq 303
  end

  it 'handles JSON-LD requests' do
    get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json', headers: { HTTP_ACCEPT: 'application/ld+json' }

    expect(response.content_type).to eq 'application/ld+json'
    json = JSON.parse(response.body)
    expect(json['tiles']).to eq [{ 'width' => 256, 'height' => 256, 'scaleFactors' => [1, 2, 4, 8, 16] }]
  end

  context 'for location-restricted documents' do
    before do
      stub_rights_xml(location_rights_xml)
    end

    context 'outside of the location' do
      it 'uses the unauthorized status code for the response' do
        get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json'
        expect(response).to have_http_status :unauthorized
      end

      context 'for a thumbnail' do
        before do
          stub_rights_xml(location_thumbnail_rights_xml)
        end

        it 'redirects requests to the degraded info.json' do
          get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json'
          expect(response).to have_http_status :redirect
          expect(response).to redirect_to('/image/iiif/degraded_nr349ct7889%252Fnr349ct7889_00_0001/info.json')
          expect(response.headers['Cache-Control']).to match(/max-age=0/)
        end
      end
    end

    context 'at the location' do
      let(:user) { User.new(ip_address: 'ip.address1') }
      before do
        allow_any_instance_of(IiifController).to receive(:current_user).and_return(user)
      end
      it 'uses the ok status code for the response' do
        get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json'
        expect(response).to have_http_status :ok
      end
    end
  end

  context 'for stanford-restricted documents' do
    before do
      stub_rights_xml(stanford_restricted_rights_xml)
    end

    it 'redirects requests to the degraded info.json' do
      get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json'
      expect(response).to have_http_status :redirect
      expect(response).to redirect_to('/image/iiif/degraded_nr349ct7889%252Fnr349ct7889_00_0001/info.json')
      expect(response.headers['Cache-Control']).to match(/max-age=0/)
    end

    context 'when connecting to the degraded url' do
      it 'serves a degraded info.json description for the original file' do
        get '/image/iiif/degraded_nr349ct7889%2Fnr349ct7889_00_0001/info.json'

        expect(response).to have_http_status :ok
        expect(controller.send(:current_image).id.druid).to eq 'nr349ct7889'
      end
    end
  end

  context 'rights xml where no one can download' do
    before do
      stub_rights_xml(world_no_download_xml)
    end
    it 'serves up regular info.json (no degraded)' do
      get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json'
      expect(response).to have_http_status :ok
    end
  end

  context 'rights xml where stanford only no download' do
    before do
      stub_rights_xml(stanford_only_no_download_xml)
    end
    it 'redirects to degraded version' do
      get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json'
      expect(response).to have_http_status :redirect
      expect(response).to redirect_to('/image/iiif/degraded_nr349ct7889%252Fnr349ct7889_00_0001/info.json')
    end
  end
end
