require 'rails_helper'

def verify_cors_headers(allow_origin, allow_credentials)
  (allow_origin == Settings.cors.allow_origin_url) && (allow_credentials == 'true')
end

def verify_origin_header(allow_origin)
  (allow_origin == '*')
end

RSpec.describe "CORS headers for Media requests", type: :request do
  before { stub_rights_xml(world_readable_rights_xml) }

  let(:druid) { 'bb582xs1304' }
  let(:filename) { 'bb582xs1304_sl.mp4' }

  context "#verify_token" do
    let(:ip_address) { '192.168.1.100' }
    let(:token) { StacksMediaToken.new(druid, filename, ip_address) }
    let(:encrypted_token) { token.to_encrypted_string }

    it 'sets the Access-Control-Allow-Origin header correctly' do
      get "/media/#{druid}/#{filename}/verify_token", params: { stacks_token: encrypted_token, user_ip: ip_address }
      expect(verify_origin_header(response.headers['Access-Control-Allow-Origin'])).to be_truthy
    end
  end

  context "#auth_check" do
    it 'sets the correct CORS headers' do
      get "/media/#{druid}/#{filename}/auth_check", params: { format: :js }
      expect(verify_cors_headers(response.headers['Access-Control-Allow-Origin'],
                                 response.headers['Access-Control-Allow-Credentials'])).to be_truthy
    end
  end
end
