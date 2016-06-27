require 'rails_helper'

describe 'IIIF routes' do
  describe 'iiif image api requests' do
    it 'routes to #show' do
      expect(get: '/image/iiif/abc/0,0,256,256/pct:25/90/bitonal.jpg').to route_to('iiif#show', identifier: 'abc', region: '0,0,256,256', size: 'pct:25', rotation: '90', quality: 'bitonal', format: 'jpg')
    end

    it 'routes with embedded slashes' do
      expect(get: '/image/iiif/abc%2Fdef/full/full/0/default.jpg').to route_to('iiif#show', identifier: 'abc/def', region: 'full', size: 'full', rotation: '0', quality: 'default', format: 'jpg')
    end

    context '#show: identifier with' do
      it 'chars not requiring URI escaping' do
        identifier = "(no_escape_needed):;=&$*.-_+!,~'.ext"
        expect(get: "/image/iiif/#{identifier}").to route_to('iiif#show', identifier: identifier)
      end

      it 'some chars requiring URI escaping' do
        identifier = 'escape_needed {} @#^ %|"`.ext'
        expect(get: "/image/iiif/#{URI.escape(identifier)}").to route_to('iiif#show', identifier: identifier)
      end

      it 'square brackets must be url escaped' do
        identifier = 'foo[brackets].bar.pdf'
        escaped_identifier = 'foo%5Bbrackets%5D.bar.pdf' # URI.escape doesn't do square brackets
        expect(get: "/image/iiif/#{escaped_identifier}").to route_to('iiif#show', identifier: identifier)
      end

      it 'question mark must be url escaped' do
        identifier = 'foo?.pdf'
        escaped_identifier = 'foo%3F.pdf' # URI.escape doesn't do question mark
        expect(get: "/image/iiif/#{escaped_identifier}").to route_to('iiif#show', identifier: identifier)
      end

      it 'ü must be url escaped' do
        skip('problem writing test:  ü decodes to \xC3\xBC')
        identifier = "fü.pdf"
        escaped_identifier = URI.escape(identifier) # becomes %C3%BC
        expect(get: "/image/iiif/#{escaped_identifier}").to route_to('iiif#show', identifier: identifier)
      end

      it '%20 in actual name (from ck155rf0207)' do
        skip('problem writing test:  %20 becomes space, over-aggressive param decoding?')
        identifier = 'ARSCJ%202008.foo.bar.pdf'
        expect(get: "/image/iiif/#{URI.escape(identifier)}").to route_to('iiif#show', identifier: identifier)
      end
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

  describe 'iiif metadata preflight requests' do
    it 'routes OPTION requests for metadata' do
      expect(options: '/image/iiif/abc/info.json').to route_to('iiif#metadata_options', identifier: 'abc')
    end
  end

  describe 'authorization' do
    it 'routes to #login_iiif' do
      expect(get: '/image/iiif/auth/abc/full/full/0/default.jpg').to route_to('webauth#login_iiif', identifier: 'abc', region: 'full', size: 'full', rotation: '0', quality: 'default', format: 'jpg')
    end
  end
end
