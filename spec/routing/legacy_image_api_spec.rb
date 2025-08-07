# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Legacy image API routes' do
  it 'routes to #show' do
    expect(get: '/image/oo000oo0000/def.png').to route_to('legacy_image_service#show', id: 'oo000oo0000', file_name: 'def', format: 'png')
    expect(get: '/image/app/oo000oo0000/def.png').to route_to('legacy_image_service#show', id: 'oo000oo0000', file_name: 'def',
                                                                                           format: 'png')
    expect(get: '/image/auth/oo000oo0000/def.png').to route_to('legacy_image_service#show', id: 'oo000oo0000', file_name: 'def',
                                                                                            format: 'png')
  end

  it 'routes to #show' do
    expect(get: '/image/oo000oo0000/def_thumb').to route_to('legacy_image_service#show', id: 'oo000oo0000', file_name: 'def', size: 'thumb')
    expect(get: '/image/oo000oo0000/def_thumb.gif').to route_to('legacy_image_service#show', id: 'oo000oo0000', file_name: 'def',
                                                                                             size: 'thumb', format: 'gif')
  end

  context 'with embedded dots' do
    it 'routes to #show' do
      expect(get: '/image/oo000oo0000/def.123.png').to route_to('legacy_image_service#show', id: 'oo000oo0000', file_name: 'def.123',
                                                                                             format: 'png')
    end
  end
end
