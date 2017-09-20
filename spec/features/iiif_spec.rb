require 'rails_helper'

RSpec.describe 'IIIF integration tests' do
  it 'can present bearer tokens for a valid user session' do
    # get the token as a webauth user
    allow_any_instance_of(ActionDispatch::Request).to receive(:remote_user).and_return('xyz')

    visit '/image/iiif/token.js'
    data = JSON.parse(page.body)

    expect(data).to include 'accessToken'

    # regenerate the token as a token-based user
    allow_any_instance_of(ActionDispatch::Request).to receive(:remote_user).and_return(nil)
    page.driver.header 'Authorization', "Token #{data['accessToken']}"

    visit '/image/iiif/token.js'
    data = JSON.parse(page.body)

    expect(page.driver.response.headers).to include 'Set-Cookie'

    expect(data).to include 'accessToken'

    # and, finally, try the request with cookie-based authentication
    page.driver.header 'Authorization', nil

    visit '/image/iiif/token.js'

    data = JSON.parse(page.body)

    expect(data).to include 'accessToken'

    # and make sure it contains the information we think it should
    u = User.from_token(data['accessToken'].sub('token="', '').sub('"', ''))

    expect(u.id).to eq 'xyz'
  end
end
