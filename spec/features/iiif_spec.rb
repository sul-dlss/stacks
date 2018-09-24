require 'rails_helper'

RSpec.describe 'IIIF integration tests' do
  let(:webauth_user) { User.create! email: 'xyz@example.com', shibboleth_groups: 'stanford:stanford' }
  it 'can present bearer tokens for a valid user session' do
    sign_in webauth_user

    visit '/image/iiif/token.js'
    data = JSON.parse(page.body)

    expect(data).to include 'accessToken'

    sign_out :user
    # regenerate the token as a token-based user
    page.driver.header 'Authorization', "Bearer #{data['accessToken']}"

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

    expect(u.email).to eq 'xyz@example.com'
  end
end
