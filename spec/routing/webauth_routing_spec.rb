# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Webauth routes' do
  it 'routes to #logout' do
    expect(get: '/auth/logout').to route_to('webauth#logout')
  end
end
