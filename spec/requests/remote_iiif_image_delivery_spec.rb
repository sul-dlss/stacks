# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "proxying image requests to a remote IIIF server (cantaloupe)" do
  let(:info_request) do
    "http://imageserver-prod.stanford.edu/iiif/2/#{image_server_path('nr349ct7889', 'image.jp2')}/info.json"
  end
  let(:info_response) do
    '{"width": 11957,"height": 15227}'
  end
  let(:image_response) do
    "http://imageserver-prod.stanford.edu/iiif/2/#{image_server_path('nr349ct7889', 'image.jp2')}/full/max/0/default.jpg"
  end
  let(:public_json) do
    Factories.legacy_cocina_with_file
  end

  before do
    allow(Cocina).to receive(:find).and_return(Cocina.new(public_json))
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
