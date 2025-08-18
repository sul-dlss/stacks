# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "File requests" do
  context 'with a versioned file structure' do
    before do
      allow(Cocina).to receive(:find).and_call_original
    end

    let(:druid) { 'nr349ct7889' }
    let(:version_id) { '1' }
    let(:file_name) { 'image.jp2' }
    let(:public_json) do
      Factories.cocina_with_file(file_name:)
    end

    describe 'OPTIONS options' do
      it 'permits Range headers for all origins' do
        options "/v2/file/#{druid}/version/#{version_id}/#{file_name}"
        expect(response).to be_successful
        expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
        expect(response.headers['Access-Control-Allow-Headers']).to include 'Range'
      end
    end

    describe 'GET file with slashes in filename' do
      let(:file_name) { 'path/to/image.jp2' }
      let(:version_id) { 'v1' }
      let(:public_json) do
        Factories.cocina_with_file(file_name:)
      end

      before do
        stub_request(:get, "https://purl.stanford.edu/#{druid}/version/#{version_id}.json")
          .to_return(status: 200, body: public_json.to_json)
      end

      it 'returns a successful HTTP response' do
        get "/v2/file/#{druid}/version/#{version_id}/#{file_name}"
        expect(response).to be_successful
        expect(Cocina).to have_received(:find).with(druid, version_id)
      end
    end

    describe 'GET missing file' do
      before do
        stub_request(:get, "https://purl.stanford.edu/xf680rd3068/version/1.json")
          .to_return(status: 200, body: public_json.to_json)
      end

      it 'returns a 400 HTTP response' do
        get '/v2/file/xf680rd3068/version/1/path/to/99999.jp2'
        expect(response).to have_http_status(:not_found)
        expect(Cocina).to have_received(:find).with('xf680rd3068', '1')
      end
    end

    describe 'GET download file' do
      before do
        stub_request(:get, "https://purl.stanford.edu/#{druid}/version/#{version_id}.json")
          .to_return(status: 200, body: public_json.to_json)
      end

      it 'sends headers for content' do
        get "/v2/file/#{druid}/version/#{version_id}/image.jp2", params: { download: 'any' }

        expect(response).to be_successful

        headers = response.headers.transform_keys(&:downcase)

        expect(headers['content-disposition']).to include('attachment; filename="image.jp2"')
        expect(headers['accept-ranges']).to eq('bytes')
        expect(headers['content-length'].to_i).to be > 0
      end
    end
  end
end
