# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Versioned File requests" do
  before do
    allow(Cocina).to receive(:find).and_return(Cocina.new(public_json))
  end

  let(:druid) { 'nr349ct7889' }
  let(:version_id) { 'v1' }
  let(:file_name) { 'image.jp2' }
  let(:public_json) do
    {
      'externalIdentifier' => druid,
      'structural' => {
        'contains' => [
          {
            'structural' => {
              'contains' => [
                {
                  'filename' => file_name,
                  'access' => {
                    'view' => 'world',
                    'download' => 'world'
                  }
                }
              ]
            }
          }
        ]
      }
    }
  end

  describe 'OPTIONS options' do
    it 'permits Range headers for all origins' do
      options "/file/#{druid}/#{version_id}/#{file_name}"
      expect(response).to be_successful
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Access-Control-Allow-Headers']).to include 'Range'
    end
  end

  describe 'GET file with slashes in filename' do
    let(:file_name) { 'path/to/image.jp2' }
    let(:version_id) { 'v1' }
    let(:public_json) do
      {
        'externalIdentifier' => druid,
        'structural' => {
          'contains' => [
            {
              'structural' => {
                'contains' => [
                  {
                    'filename' => file_name,
                    'access' => {
                      'view' => 'world',
                      'download' => 'world'
                    }
                  }
                ]
              }
            }
          ]
        }
      }
    end

    before do
      allow_any_instance_of(V2::VersionsController).to receive(:send_file)
        .with('spec/fixtures/nr/349/ct/7889/path/to/image.jp2', disposition: :inline)
    end

    it 'returns a successful HTTP response' do
      get "/v2/file/#{druid}/#{version_id}/#{file_name}"
      expect(response).to be_successful
    end
  end

  describe 'GET missing file' do
    it 'returns a 400 HTTP response' do
      get '/v2/file/xf680rd3068/v1/path/to/99999.jp2'
      expect(response).to have_http_status(:not_found)
    end
  end
end
