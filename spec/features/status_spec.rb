require 'rails_helper'

describe 'application and dependency monitoring' do
  it '/status checks if Rails app is running' do
    visit '/status'
    expect(page.status_code).to eq 200
    expect(page).to have_text('Application is running')
  end
  it '/status/all checks if required dependencies are ok and also shows non-crucial dependencies' do
    visit '/status/all'
    expect(page).to have_text('purl_url') # required check
    expect(page).to have_text('imageserver_url') # non-crucial check
  end
  it '/status/imageserver_url' do
    visit '/status/imageserver_url'
    expect(page).to have_text('imageserver_url')
  end
end
