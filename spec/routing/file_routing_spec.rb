require 'rails_helper'

describe 'file routes' do
  it 'routes to #show' do
    expect(get: '/file/abc/def.pdf').to route_to('file#show', id: 'abc', file_name: 'def.pdf')
  end

  context '#show (download): filename with' do
    it 'chars not requiring URI escaping' do
      filename = "(no_escape_needed):;=&$*.-_+!,~'.ext"
      expect(get: "/file/oo000oo0000/#{filename}").to route_to(
        'file#show', id: 'oo000oo0000', file_name: filename)
    end

    it 'some chars requiring URI escaping' do
      filename = 'escape_needed {} @#^ %|"`.ext'
      expect(get: "/file/oo000oo0000/#{URI.escape(filename)}").to route_to(
        'file#show', id: 'oo000oo0000', file_name: filename)
    end

    it 'square brackets must be url escaped' do
      filename = 'foo[brackets].bar.pdf'
      escaped_filename = 'foo%5Bbrackets%5D.bar.pdf' # URI.escape doesn't do square brackets
      expect(get: "/file/oo000oo0000/#{escaped_filename}").to route_to(
        'file#show', id: 'oo000oo0000', file_name: filename)
    end

    it 'question mark must be url escaped' do
      filename = 'foo?.pdf'
      escaped_filename = 'foo%3F.pdf' # URI.escape doesn't do question mark
      expect(get: "/file/oo000oo0000/#{escaped_filename}").to route_to(
        'file#show', id: 'oo000oo0000', file_name: filename)
    end

    it 'ü must be url escaped' do
      skip('problem writing test:  ü decodes to \xC3\xBC')
      filename = "fü.pdf"
      escaped_filename = URI.escape(filename) # becomes %C3%BC
      expect(get: "/file/oo000oo0000/#{escaped_filename}").to route_to(
        'file#show', id: 'oo000oo0000', file_name: filename)
    end

    it '%20 in actual name (from ck155rf0207)' do
      skip('problem writing test:  %20 becomes space, over-aggressive param decoding?')
      filename = 'ARSCJ%202008.foo.bar.pdf'
      expect(get: "/file/oo000oo0000/#{URI.escape(filename)}").to route_to(
        'file#show', id: 'oo000oo0000', file_name: filename)
    end
  end

  describe 'authorization' do
    it 'routes to webauth#login_file' do
      expect(get: '/file/auth/abc/def.pdf').to route_to('webauth#login_file', id: 'abc', file_name: 'def.pdf')
    end

    it 'routes to webauth#login_file' do
      expect(get: '/file/app/abc/def.pdf').to route_to('webauth#login_file', id: 'abc', file_name: 'def.pdf')
    end
  end
end
