# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "File requests" do
  before do
    allow(Cocina).to receive(:find).and_return(Cocina.new(public_json))
  end

  let(:druid) { 'bb000cr7262' }
  let(:file_name) { 'image.jp2' }
  let(:public_json) do
    Factories.legacy_cocina_with_file
  end

  describe 'OPTIONS options' do
    it 'permits Range headers for all origins' do
      options "/file/#{druid}/#{file_name}"
      expect(response).to be_successful
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Access-Control-Allow-Headers']).to include 'Range'
    end
  end

  describe 'GET file with slashes in filename' do
    let(:file_name) { 'path/to/image.jp2' }
    let(:public_json) do
      Factories.cocina_with_file(file_name:)
    end

    before do
      allow_any_instance_of(FileController).to receive(:send_file)
        .with('spec/fixtures/bb/000/cr/7262/bb000cr7262/content/8ff299eda08d7c506273840d52a03bf3', filename: 'path/to/image.jp2', disposition: :inline)
    end

    it 'returns a successful HTTP response' do
      get "/file/#{druid}/#{file_name}"
      expect(response).to be_successful
    end
  end

  describe 'GET missing file' do
    it 'returns a 400 HTTP response' do
      get '/file/xf680rd3068/path/to/99999.jp2'
      expect(response).to have_http_status(:not_found)
    end
  end
end
