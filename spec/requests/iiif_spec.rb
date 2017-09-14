require 'rails_helper'

RSpec.describe 'IIIF API' do
  let(:iiif_uri) { 'http://www.example.com/image/iiif/nr349ct7889%252Fnr349ct7889_00_0001' }
  let(:file_uri) { 'file:///stacks/nr/349/ct/7889/nr349ct7889_00_0001.jp2' }
  let(:djatoka_metadata) do
    instance_double(Djatoka::Metadata, to_iiif_json: metadata)
  end
  let(:metadata) do
    JSON.pretty_generate(
      tiles: [{ 'width' => 256, "height" => 256, "scaleFactors" => [1, 2, 4, 8, 16] }]
    )
  end
  let(:resolver) { instance_double(Djatoka::Resolver, metadata: djatoka_metadata) }

  before do
    # this is required because you can't dump a singleton (double)
    stub_rights_xml(world_readable_rights_xml)
    allow(Rails.cache).to receive(:fetch).and_yield
    allow(Djatoka::Resolver).to receive(:new).and_return(resolver)
    allow(djatoka_metadata).to receive(:perform).and_return(djatoka_metadata)
    allow_any_instance_of(StacksImage).to receive_messages(exist?: true,
                                                           etag: 'etag',
                                                           mtime: Time.zone.now)
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
      let(:iiif_uri) { 'http://www.example.com/image/iiif/degraded_nr349ct7889%252Fnr349ct7889_00_0001' }

      it 'serves a degraded info.json description for the original file' do
        get '/image/iiif/degraded_nr349ct7889%2Fnr349ct7889_00_0001/info.json'

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
