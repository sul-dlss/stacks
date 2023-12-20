# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'CDL routes' do
  it 'routes to #show' do
    expect(get: '/cdl/druid').to route_to('cdl#show', id: 'druid')
  end

  it 'routes to #create' do
    expect(get: '/auth/iiif/cdl/druid/checkout').to route_to('cdl#create', id: 'druid')
  end

  it 'routes to #delete' do
    expect(get: '/auth/iiif/cdl/druid/checkin').to route_to('cdl#delete', id: 'druid')
  end
end
