# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'application and dependency monitoring' do
  it '/status checks if Rails app is running' do
    visit '/status'
    expect(page.status_code).to eq 200
    expect(page).to have_text('Application is running')
  end

  context "all dependencies" do
    before do
      allow_any_instance_of(OkComputer::HttpCheck).to receive(:check).and_return(true)
    end

    it '/status/all checks if required dependencies are ok and also shows non-crucial dependencies' do
      visit '/status/all'
      expect(page).to have_text('purl_url') # required check
      expect(page).to have_text('imageserver_url') # non-crucial check
    end
  end

  context "image server" do
    before do
      allow_any_instance_of(OkComputer::HttpCheck).to receive(:check).and_return(true)
    end

    it '/status/imageserver_url' do
      visit '/status/imageserver_url'
      expect(page).to have_text('imageserver_url')
    end
  end
end
