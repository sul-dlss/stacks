require 'rails_helper'

RSpec.describe 'IIIF API' do
  it 'redirects base uri requests to the info.json document' do
    get '/image/iiif/abc'
    
    expect(response).to redirect_to('/image/iiif/abc/info.json')
    expect(response.status).to eq 303
  end
end
