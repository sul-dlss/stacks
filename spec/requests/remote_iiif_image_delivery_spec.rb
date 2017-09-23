# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "It proxies image requests to a remote IIIF server (canteloupe)" do
  let(:info_request) do
    "https://sul-imageserver-uat.stanford.edu/cantaloupe/iiif/2/nr%2F349%2Fct%2F7889%2Fimage.jp2/info.json"
  end
  let(:info_response) do
    '{
  "width": 11957,
  "height": 15227
}'
  end

  let(:image_response) do
    "https://sul-imageserver-uat.stanford.edu/cantaloupe/iiif/2/nr%2F349%2Fct%2F7889%2Fimage.jp2/full/max/0/default.jpg"
  end

  before do
    stub_rights_xml(world_readable_rights_xml)
    allow(Settings.stacks).to receive(:storage_root).and_return('spec/fixtures')
    stub_request(:get, info_request)
      .to_return(status: 200, body: info_response)
    stub_request(:get, image_response)
      .to_return(status: 200, body: "image contents")
  end

  it 'returns an image' do
    get '/image/iiif/nr349ct7889%2Fimage/full/max/0/default.jpg'
    expect(response.body).to eq 'image contents'
  end
end
