require 'rails_helper'

RSpec.describe 'IIIF API' do
  let(:stacks_image) do
    instance_double(StacksImage, exist?: true,
                                 etag: 'etag',
                                 mtime: Time.zone.now,
                                 world_unrestricted?: true,
                                 world_rights: true,
                                 stanford_restricted?: false,
                                 stanford_only_rights: false)
  end
  it 'redirects base uri requests to the info.json document' do
    get '/image/iiif/abc'

    expect(response).to redirect_to('/image/iiif/abc/info.json')
    expect(response.status).to eq 303
  end

  it 'handles JSON-LD requests' do
    allow(StacksImage).to receive(:new).with(hash_including(id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001'))
      .and_return(stacks_image)
    get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json', headers: { HTTP_ACCEPT: 'application/ld+json' }

    expect(response.content_type).to eq 'application/ld+json'
  end
end
