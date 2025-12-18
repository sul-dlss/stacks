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

    describe 'HEAD download file' do
      before do
        stub_request(:get, "https://purl.stanford.edu/#{druid}/version/#{version_id}.json")
          .to_return(status: 200, body: public_json.to_json)
      end

      context 'without a range header' do
        it 'sends headers for content' do
          head "/v2/file/#{druid}/version/#{version_id}/image.jp2", params: { download: 'any' }

          expect(response).to be_ok
          headers = response.headers.transform_keys(&:downcase)
          expect(headers['accept-ranges']).to eq('bytes')
          expect(headers['content-length']).to eq "12345"
        end
      end

      context 'with a range header' do
        it 'sends headers for content' do
          head "/v2/file/#{druid}/version/#{version_id}/image.jp2", params: { download: 'any' }, headers: { 'Range' => 'bytes=0-' }

          expect(response).to be_ok
          headers = response.headers.transform_keys(&:downcase)
          expect(headers['accept-ranges']).to eq('bytes')
          expect(headers['content-length']).to eq "12345"
        end
      end
    end

    describe 'GET file with range requests' do
      before do
        stub_request(:get, "https://purl.stanford.edu/#{druid}/version/#{version_id}.json")
          .to_return(status: 200, body: public_json.to_json)
      end

      it 'returns 206 partial content for valid range request' do
        get "/v2/file/#{druid}/version/#{version_id}/#{file_name}",
            headers: { 'Range' => 'bytes=0-499' }

        expect(response).to have_http_status(:partial_content)
        expect(response.headers['Content-Range']).to eq('bytes 0-499/12345')
        expect(response.headers['Content-Length']).to eq('500')
        expect(response.headers['Accept-Ranges']).to eq('bytes')
      end

      it 'returns 206 partial content for suffix range request' do
        get "/v2/file/#{druid}/version/#{version_id}/#{file_name}",
            headers: { 'Range' => 'bytes=-1000' }

        expect(response).to have_http_status(:partial_content)
        expect(response.headers['Content-Range']).to eq('bytes 11345-12344/12345')
        expect(response.headers['Content-Length']).to eq('1000')
      end

      it 'returns 206 partial content for prefix range request' do
        get "/v2/file/#{druid}/version/#{version_id}/#{file_name}",
            headers: { 'Range' => 'bytes=12000-' }

        expect(response).to have_http_status(:partial_content)
        expect(response.headers['Content-Range']).to eq('bytes 12000-12344/12345')
        expect(response.headers['Content-Length']).to eq('345')
      end

      it 'returns 416 range not satisfiable for invalid range' do
        get "/v2/file/#{druid}/version/#{version_id}/#{file_name}",
            headers: { 'Range' => 'bytes=50000-60000' }

        expect(response).to have_http_status(:range_not_satisfiable)
        expect(response.headers['Content-Range']).to eq('bytes */12345')
      end

      it 'returns 416 range not satisfiable for malformed range' do
        get "/v2/file/#{druid}/version/#{version_id}/#{file_name}",
            headers: { 'Range' => 'bytes=invalid' }

        expect(response).to have_http_status(:range_not_satisfiable)
        expect(response.headers['Content-Range']).to eq('bytes */12345')
      end

      it 'returns full content when no range header is provided' do
        get "/v2/file/#{druid}/version/#{version_id}/#{file_name}"

        expect(response).to have_http_status(:ok)
        expect(response.headers['Content-Length'].to_i).to be > 0
        expect(response.headers['Accept-Ranges']).to eq('bytes')
        expect(response.headers['Content-Range']).to be_nil
      end
    end
  end
end
