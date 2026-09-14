# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'File download proxy' do
  let(:path) { '/file/bb000cr7262/image.jp2' }
  let(:metadata) { Factories.cocina_with_file }
  let(:s3_client) { instance_double(Aws::S3::Client, head_object: s3_head) }
  let(:s3_head) { instance_double(Aws::S3::Types::HeadObjectOutput, last_modified: Time.utc(2026, 1, 1)) }
  let(:internal_path) { '/_private_s3/bb/000/cr/7262/bb000cr7262/content/8ff299eda08d7c506273840d52a03bf3' }

  before do
    allow(Settings.features).to receive(:download_proxy).and_return(true)
    allow(S3ClientFactory).to receive(:create_client).and_return(s3_client)
    stub_request(:get, 'https://purl.stanford.edu/bb000cr7262.json')
      .to_return(status: 200, body: metadata.to_json)
  end

  it 'authorizes and tracks a download without reading the S3 body' do
    allow(s3_client).to receive(:get_object)
    allow(TrackDownloadJob).to receive(:perform_later)

    get path, params: { download: 'true' }

    expect(response).to have_http_status(:ok)
    expect(response.body).to be_empty
    expect(response.headers['X-Accel-Redirect']).to eq internal_path
    expect(response.headers['Content-Type']).to eq 'image/jp2'
    expect(response.headers['Content-Disposition']).to include('attachment; filename="image.jp2"')
    expect(response.headers['Access-Control-Expose-Headers']).to eq 'Content-Range'
    expect(s3_client).not_to have_received(:get_object)
    expect(TrackDownloadJob).to have_received(:perform_later).with(hash_including(druid: 'bb000cr7262', file: 'image.jp2'))
  end

  it 'resolves versioned files through Cocina' do
    stub_request(:get, 'https://purl.stanford.edu/bb000cr7262/version/1.json')
      .to_return(status: 200, body: metadata.to_json)
    get '/v2/file/bb000cr7262/version/1/image.jp2'

    expect(response.headers['X-Accel-Redirect']).to eq internal_path
  end

  it 'hands off HEAD without a body or a range' do
    head path, headers: { 'Range' => 'bytes=0-99' }

    expect(response.body).to be_empty
    expect(response.headers['X-Accel-Redirect']).to eq internal_path
    expect(response.headers['X-Stacks-Range']).to be_nil
  end

  it 'normalizes a suffix range for the proxy' do
    get path, headers: { 'Range' => 'bytes=-100' }

    expect(response.headers['X-Stacks-Range']).to eq 'bytes=12245-12344'
    expect(response.headers['X-Accel-Redirect']).to eq internal_path
  end

  it 'rejects invalid ranges without handing off' do
    get path, headers: { 'Range' => 'bytes=50000-60000' }

    expect(response).to have_http_status(:range_not_satisfiable)
    expect(response.headers['Content-Range']).to eq 'bytes */12345'
    expect(response.headers['X-Accel-Redirect']).to be_nil
  end

  it 'ignores a range when If-Range is stale' do
    get path, headers: { 'Range' => 'bytes=0-99', 'If-Range' => 'Wed, 01 Jan 2025 00:00:00 GMT' }

    expect(response.headers['X-Accel-Redirect']).to eq internal_path
    expect(response.headers['X-Stacks-Range']).to be_nil
  end

  it 'honors a range when If-Range matches the modification time' do
    get path, headers: { 'Range' => 'bytes=0-99', 'If-Range' => s3_head.last_modified.httpdate }

    expect(response.headers['X-Stacks-Range']).to eq 'bytes=0-99'
  end

  it 'answers conditional requests without handing off' do
    get path
    get path, headers: { 'If-None-Match' => response.headers['ETag'] }

    expect(response).to have_http_status(:not_modified)
    expect(response.headers['X-Accel-Redirect']).to be_nil
  end

  context 'when download is forbidden' do
    let(:metadata) { Factories.cocina_with_file(file_access: { 'view' => 'none', 'download' => 'none' }) }

    it 'does not expose the internal path, even for a conditional request' do
      get path, headers: { 'If-Modified-Since' => 'Thu, 01 Jan 2037 00:00:00 GMT' }

      expect(response).to have_http_status(:forbidden)
      expect(response.headers['X-Accel-Redirect']).to be_nil
    end
  end

  context 'when login is required' do
    let(:metadata) { Factories.cocina_with_file(file_access: { 'view' => 'stanford', 'download' => 'stanford' }) }

    it 'preserves the login redirect' do
      get path

      expect(response).to redirect_to(auth_file_url(id: 'bb000cr7262', file_name: 'image.jp2'))
      expect(response.headers['X-Accel-Redirect']).to be_nil
    end
  end
end
