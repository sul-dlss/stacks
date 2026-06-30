# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Application and dependency monitoring' do
  it 'checks if Rails app is running' do
    get '/status'
    expect(response).to have_http_status(:ok)
    expect(response.body).to include('Application is running')
  end

  context 'when checking all dependencies' do
    before do
      allow_any_instance_of(OkComputer::HttpCheck).to receive(:check).and_return(true) # rubocop:disable RSpec/AnyInstance
    end

    it 'checks if required dependencies are ok and also shows non-crucial dependencies' do
      get '/status/all'
      expect(response.body).to include('purl_url') # required check
      expect(response.body).to include('imageserver_url') # non-crucial check
    end
  end

  context 'when checking the image server' do
    before do
      allow_any_instance_of(OkComputer::HttpCheck).to receive(:check).and_return(true) # rubocop:disable RSpec/AnyInstance
    end

    it 'checks the image server status' do
      get '/status/imageserver_url'
      expect(response.body).to include('imageserver_url')
    end
  end
end
