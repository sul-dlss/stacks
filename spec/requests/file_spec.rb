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
    # The size of the fixture object in S3, not the size in the cocina
    let(:file_size) { 11_043 }

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
        expect(headers['access-control-expose-headers']).to eq('Content-Range')
        expect(headers['content-length'].to_i).to be > 0
      end
    end

    describe 'GET file streaming errors' do
      let(:path) { "/v2/file/#{druid}/version/#{version_id}/#{file_name}" }

      before do
        stub_request(:get, "https://purl.stanford.edu/#{druid}/version/#{version_id}.json")
          .to_return(status: 200, body: public_json.to_json)
        allow(Honeybadger).to receive(:notify)
      end

      # Pass each chunk of the response body to the block, which stands in for writing to the client
      def send_response(env = {}, &)
        _status, _headers, body = Rails.application.call(Rack::MockRequest.env_for(path, env))
        body.each(&)
      ensure
        body&.close
      end

      context 'when the client disconnects' do
        let(:write_error) { Errno::EPIPE.new }

        it "doesn't report it to Honeybadger" do
          expect { send_response { raise write_error } }.to raise_error(Errno::EPIPE) { |error| expect(error).to be write_error }
          expect(Honeybadger).not_to have_received(:notify)
        end

        it "also doesn't report it to Honeybadger during a range request" do
          expect { send_response('HTTP_RANGE' => 'bytes=0-99') { raise write_error } }
            .to raise_error(Errno::EPIPE) { |error| expect(error).to be write_error }
          expect(Honeybadger).not_to have_received(:notify)
        end
      end

      context 'when reading from S3 fails' do
        let(:s3_client) { S3ClientFactory.create_client }
        let(:streaming_error) { Aws::S3::Plugins::NonRetryableStreamingError.new(StandardError.new('connection reset')) }

        before do
          allow(S3ClientFactory).to receive(:create_client).and_return(s3_client)
          allow(s3_client).to receive(:get_object).and_raise(streaming_error)
        end

        it 'reports the error to Honeybadger' do
          expect { send_response { nil } }.to raise_error(streaming_error)
          expect(Honeybadger).to have_received(:notify).with(streaming_error)
        end
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
          expect(headers['content-length']).to eq file_size.to_s
          expect(headers['content-disposition']).to include('attachment; filename="image.jp2"')
          expect(headers['content-type']).to eq "image/jp2"
        end
      end

      context 'with a range header' do
        it 'sends headers for content' do
          head "/v2/file/#{druid}/version/#{version_id}/image.jp2", params: { download: 'any' }, headers: { 'Range' => 'bytes=0-' }

          expect(response).to be_ok
          headers = response.headers.transform_keys(&:downcase)
          expect(headers['accept-ranges']).to eq('bytes')
          expect(headers['content-length']).to eq file_size.to_s
          expect(headers['content-disposition']).to include('attachment; filename="image.jp2"')
          expect(headers['content-type']).to eq "image/jp2"
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
        expect(response.headers['Content-Range']).to eq('bytes 0-499/11043')
        expect(response.headers['Content-Length']).to eq('500')
        expect(response.headers['Accept-Ranges']).to eq('bytes')
      end

      it 'returns 206 partial content for suffix range request' do
        get "/v2/file/#{druid}/version/#{version_id}/#{file_name}",
            headers: { 'Range' => 'bytes=-1000' }

        expect(response).to have_http_status(:partial_content)
        expect(response.headers['Content-Range']).to eq('bytes 10043-11042/11043')
        expect(response.headers['Content-Length']).to eq('1000')
      end

      it 'returns 206 partial content for prefix range request' do
        get "/v2/file/#{druid}/version/#{version_id}/#{file_name}",
            headers: { 'Range' => 'bytes=11000-' }

        expect(response).to have_http_status(:partial_content)
        expect(response.headers['Content-Range']).to eq('bytes 11000-11042/11043')
        expect(response.headers['Content-Length']).to eq('43')
      end

      it 'returns 416 range not satisfiable for invalid range' do
        get "/v2/file/#{druid}/version/#{version_id}/#{file_name}",
            headers: { 'Range' => 'bytes=50000-60000' }

        expect(response).to have_http_status(:range_not_satisfiable)
        expect(response.headers['Content-Range']).to eq('bytes */11043')
      end

      it 'returns 416 range not satisfiable for malformed range' do
        get "/v2/file/#{druid}/version/#{version_id}/#{file_name}",
            headers: { 'Range' => 'bytes=invalid' }

        expect(response).to have_http_status(:range_not_satisfiable)
        expect(response.headers['Content-Range']).to eq('bytes */11043')
      end

      it 'returns full content when no range header is provided' do
        get "/v2/file/#{druid}/version/#{version_id}/#{file_name}"

        expect(response).to have_http_status(:ok)
        expect(response.headers['Content-Length'].to_i).to be > 0
        expect(response.headers['Accept-Ranges']).to eq('bytes')
        expect(response.headers['Content-Range']).to be_nil
      end
    end

    # The request helpers above use rack-test, which sends HTTP/1.0 requests and replaces the Content-Length
    # of any response with a body by the size of the body it read, so they can't show whether the app sent one.
    # Call the app like Puma or Passenger do instead: Rack::MockRequest sends HTTP/1.1 and keeps the headers
    # as the app set them, and Rack::Lint fails if the Content-Length doesn't match the body.
    describe 'Content-Length of HTTP/1.1 responses' do
      subject(:rack_response) { Rack::MockRequest.new(Rails.application).request(method, path, lint: true, **env) }

      let(:path) { "/v2/file/#{druid}/version/#{version_id}/#{file_name}" }
      let(:env) { {} }
      let(:s3_client) { S3ClientFactory.create_client }

      before do
        stub_request(:get, "https://purl.stanford.edu/#{druid}/version/#{version_id}.json")
          .to_return(status: 200, body: public_json.to_json)
        allow(S3ClientFactory).to receive(:create_client).and_return(s3_client)
        allow(s3_client).to receive(:get_object).and_call_original
      end

      context 'with a HEAD request' do
        let(:method) { 'HEAD' }

        it 'sends the file size and the headers of a GET, without fetching the file' do
          expect(rack_response.status).to eq 200
          expect(rack_response.headers).to include('content-length' => file_size.to_s,
                                                   'content-type' => 'image/jp2',
                                                   'content-disposition' => a_string_starting_with('inline'))
          expect(rack_response.headers).not_to include('transfer-encoding', 'content-range')
          expect(rack_response.body).to be_empty
          expect(s3_client).not_to have_received(:get_object)
        end
      end

      context 'with a HEAD request for a range' do
        let(:method) { 'HEAD' }
        let(:env) { { 'HTTP_RANGE' => 'bytes=0-99' } }

        it 'ignores the range and sends the file size' do
          expect(rack_response.status).to eq 200
          expect(rack_response.headers['content-length']).to eq file_size.to_s
          expect(rack_response.headers).not_to include('content-range')
          expect(s3_client).not_to have_received(:get_object)
        end
      end

      context 'with a GET request' do
        let(:method) { 'GET' }

        it 'streams the file with its size' do
          expect(rack_response.status).to eq 200
          expect(rack_response.headers['content-length']).to eq file_size.to_s
          expect(rack_response.headers).not_to include('transfer-encoding')
          expect(rack_response.body.bytesize).to eq file_size
        end
      end

      context 'with a GET request for a range' do
        let(:method) { 'GET' }
        let(:env) { { 'HTTP_RANGE' => 'bytes=100-199' } }

        it 'streams the range with its size' do
          expect(rack_response.status).to eq 206
          expect(rack_response.headers).to include('content-length' => '100', 'content-range' => "bytes 100-199/#{file_size}")
          expect(rack_response.body.bytesize).to eq 100
        end
      end
    end
  end
end
