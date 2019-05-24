# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'webauth/logout.html.erb' do
  it 'gives directions for quitting the browser session' do
    render
    expect(rendered).to match(/Your single sign-on cookie has been deleted./)
  end
end
