require 'rails_helper'

RSpec.describe 'IIIF API' do
  let(:stacks_image) do
    StacksImage.new
  end

  before do
    allow(stacks_image).to receive_messages(
      exist?: true,
      etag: 'etag',
      mtime: Time.zone.now,
      info: {},
      image_width: 0,
      image_height: 0
    )
    allow(StacksImage).to receive(:new).with(hash_including(id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001'))
      .and_return(stacks_image)
  end

  it 'redirects base uri requests to the info.json document' do
    get '/image/iiif/abc'

    expect(response).to redirect_to('/image/iiif/abc/info.json')
    expect(response.status).to eq 303
  end

  it 'handles JSON-LD requests' do
    get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json', headers: { HTTP_ACCEPT: 'application/ld+json' }

    expect(response.content_type).to eq 'application/ld+json'
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

    it 'serves a degraded info.json description for the original file' do
      get '/image/iiif/degraded_nr349ct7889%2Fnr349ct7889_00_0001/info.json'

      expect(controller.send(:identifier_params)).to include id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001'
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
