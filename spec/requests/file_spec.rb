# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "File requests", type: :request do
  before do
    allow(Purl).to receive(:public_xml).and_return('<publicObject />')
  end

  describe 'OPTIONS options' do
    it 'permits Range headers for all origins' do
      options '/file/xf680rd3068/xf680rd3068_1.jp2'
      expect(response).to be_successful
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Access-Control-Allow-Headers']).to include 'Range'
    end
  end

  describe 'GET file with slashes in filename' do
    let(:stacks_file) { StacksFile.new(id: 'xf680rd3068', file_name: 'path/to/xf680rd3068_1.jp2') }
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

    before do
      allow_any_instance_of(FileController).to receive(:send_file).with(stacks_file.path, disposition: :inline)
      allow(Purl).to receive(:public_xml).and_return(world_rights)
    end

    it 'returns a successful HTTP response' do
      get '/file/xf680rd3068/path/to/xf680rd3068_1.jp2'
      expect(response).to be_successful
    end
  end
end
