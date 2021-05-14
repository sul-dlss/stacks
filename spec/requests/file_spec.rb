# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Authentication for File requests", type: :request do
  describe 'OPTIONS options' do
    before do
      allow(Purl).to receive(:public_xml).and_return('<publicObject />')
    end

    it 'permits Range headers for all origins' do
      options '/file/xf680rd3068/xf680rd3068_1.jp2'
      expect(response).to be_successful
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
      expect(response.headers['Access-Control-Allow-Headers']).to include 'Range'
    end
  end
end
