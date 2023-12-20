# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "CORS headers for Media requests", type: :request do
  before do
    stub_rights_xml(world_readable_rights_xml)
    allow(Purl).to receive(:public_json).and_return(public_json)
  end

  let(:public_json) do
    {
      'structural' => {
        'contains' => [
          {
            'structural' => {
              'contains' => [
                {
                  'filename' => filename,
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

  let(:druid) { 'bb582xs1304' }
  let(:filename) { 'bb582xs1304_sl.mp4' }

  describe "#verify_token" do
    let(:ip_address) { '192.168.1.100' }
    let(:token) { StacksMediaToken.new(druid, filename, ip_address) }
    let(:encrypted_token) { token.to_encrypted_string }

    before do
      get "/media/#{druid}/#{filename}/verify_token", params: { stacks_token: encrypted_token, user_ip: ip_address }
    end

    it 'sets the Access-Control-Allow-Origin header correctly' do
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
    end
  end

  describe "#auth_check" do
    before do
      get "/media/#{druid}/#{filename}/auth_check", params: { format: :js }, headers: { 'Origin' => Settings.cors.allow_origin_url }
    end

    it 'sets the correct CORS headers' do
      expect(response.headers['Access-Control-Allow-Origin']).to eq Settings.cors.allow_origin_url
      expect(response.headers['Access-Control-Allow-Credentials']).to be true
    end
  end
end
