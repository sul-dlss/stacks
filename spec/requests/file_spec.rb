# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "File requests" do
  before do
    allow(Purl).to receive_messages(public_xml: '<publicObject />', public_json:)
  end

  let(:druid) { 'nr349ct7889' }
  let(:file_name) { 'image.jp2' }
  let(:public_json) do
    {
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
      options "/file/#{druid}/#{file_name}"
      expect(response).to be_successful
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Access-Control-Allow-Headers']).to include 'Range'
    end
  end

  describe 'GET file with slashes in filename' do
    let(:file_name) { 'path/to/image.jp2' }
    let(:stacks_file) { StacksFile.new(id: druid, file_name:) }
    let(:world_rights) do
      <<-EOF
        <publicObject>
          <rightsMetadata>
            <access type="read">
              <machine>
                <world/>
              </machine>
            </access>
          </rightsMetadata>
        </publicObject>
      EOF
    end
    let(:public_json) do
      {
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
      allow(StacksFile).to receive(:new).and_return(stacks_file)
      allow(stacks_file).to receive(:path)
      allow_any_instance_of(FileController).to receive(:send_file).with(stacks_file.path, disposition: :inline)
      allow(Purl).to receive(:public_xml).and_return(world_rights)
    end

    it 'returns a successful HTTP response' do
      get "/file/#{druid}/#{file_name}"
      expect(response).to be_successful
    end
  end

  describe 'GET missing file' do
    before do
      allow(StacksFile).to receive(:new).and_return(stacks_file)
      allow(stacks_file).to receive(:path)
    end

    let(:stacks_file) { StacksFile.new(id: druid, file_name: 'path/to/99999.jp2') }

    it 'returns a 400 HTTP response' do
      get "/file/#{druid}/path/to/99999.jp2"
      expect(response).to have_http_status(Settings.features.cocina ? :not_found : :forbidden)
    end
  end
end
