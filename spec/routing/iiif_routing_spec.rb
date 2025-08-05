# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'IIIF routes' do
  describe 'iiif image api requests' do
    it 'routes to #show' do
      expect(get: '/image/iiif/oo000oo0000/def/0,0,256,256/pct:25/90/bitonal.jpg')
        .to route_to('iiif#show', id: 'oo000oo0000',
                                  file_name: 'def', region: '0,0,256,256', size: 'pct:25',
                                  rotation: '90', quality: 'bitonal', format: 'jpg')
      expect(get: '/image/iiif/oo000oo0000%2Fdef/full/full/0/default.jpg')
        .to route_to('iiif#show', identifier: 'oo000oo0000/def',
                                  region: 'full', size: 'full', rotation: '0', quality: 'default', format: 'jpg')
    end
  end

  describe 'iiif metadata api requests' do
    it 'routes to #metadata' do
      expect(get: '/image/iiif/oo000oo0000/abc/info.json').to route_to('iiif#metadata', id: 'oo000oo0000', file_name: 'abc')
      expect(get: '/image/iiif/oo000oo0000%2Fabc/info.json').to route_to('iiif#metadata', identifier: 'oo000oo0000/abc')
    end
  end

  describe 'iiif metadata preflight requests' do
    it 'routes OPTION requests for metadata' do
      expect(options: '/image/iiif/oo000oo0000/abc/info.json')
        .to route_to('iiif#metadata_options', id: 'oo000oo0000', file_name: 'abc')
      expect(options: '/image/iiif/oo000oo0000%2Fabc/info.json')
        .to route_to('iiif#metadata_options', identifier: 'oo000oo0000/abc')
    end
  end

  describe 'authorization' do
    it 'routes to #login_iiif' do
      expect(get: '/image/iiif/auth/oo000oo0000/abc/full/full/0/default.jpg')
        .to route_to('webauth#login_iiif', id: 'oo000oo0000',
                                           file_name: 'abc', region: 'full', size: 'full', rotation: '0', quality: 'default', format: 'jpg')
    end
  end
end
