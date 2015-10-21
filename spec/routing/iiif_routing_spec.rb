require 'rails_helper'

# rubocop:disable Metrics/LineLength
describe 'IIIF routes' do
  describe 'iiif image api requests' do
    it 'routes to #show' do
      expect(get: '/image/iiif/abc/0,0,256,256/pct:25/90/bitonal.jpg').to route_to('iiif#show', identifier: 'abc', region: '0,0,256,256', size: 'pct:25', rotation: '90', quality: 'bitonal', format: 'jpg')
    end

    it 'routes with embedded slashes' do
      expect(get: '/image/iiif/abc%2Fdef/full/full/0/default.jpg').to route_to('iiif#show', identifier: 'abc/def', region: 'full', size: 'full', rotation: '0', quality: 'default', format: 'jpg')
    end
  end

  describe 'iiif metadata api requests' do
    it 'routes to #metadata' do
      expect(get: '/image/iiif/abc/info.json').to route_to('iiif#metadata', identifier: 'abc')
    end

    it 'routes with embedded slashes' do
      expect(get: '/image/iiif/abc%2Fdef/info.json').to route_to('iiif#metadata', identifier: 'abc/def')
    end
  end

  describe 'authorization' do
    it 'routes to #login_iiif' do
      expect(get: '/image/iiif/auth/abc/full/full/0/default.jpg').to route_to('webauth#login_iiif', identifier: 'abc', region: 'full', size: 'full', rotation: '0', quality: 'default', format: 'jpg')
    end
  end
end
# rubocop:enable Metrics/LineLength
