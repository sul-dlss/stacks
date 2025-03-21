# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "CORS headers for Media requests" do
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
end
