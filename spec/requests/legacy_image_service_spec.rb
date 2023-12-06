# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Legacy image service' do
  context 'with an invalid zoom value' do
    before do
      get '/image/nr349ct7889/nr349ct7889_00_0001.jpg?zoom=test&region=256,256,256,256'
    end

    it 'is not found' do
      expect(response).to have_http_status(:not_found)
    end
  end

  context 'with an invalid region value' do
    before do
      get '/image/nr349ct7889/nr349ct7889_00_0001.jpg?zoom=50&region=test'
    end

    it 'is not found' do
      expect(response).to have_http_status(:not_found)
    end
  end
end
