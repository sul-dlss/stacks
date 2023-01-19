# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'file routes' do
  it 'routes to #show' do
    expect(get: '/file/oo000oo0000/def.pdf').to route_to('file#show', id: 'oo000oo0000', file_name: 'def.pdf')
  end

  it 'routes to #show even with a druid namespace' do
    expect(get: '/file/druid:oo000oo0000/def.pdf').to route_to('file#show', id: 'oo000oo0000', file_name: 'def.pdf')
  end

  describe '#show (download): filename with' do
    it 'chars not requiring URI escaping' do
      filename = "(no_escape_needed)/:;=&$*.-_+!,~'.ext"
      expect(get: "/file/oo000oo0000/#{filename}").to route_to(
        'file#show', id: 'oo000oo0000', file_name: filename)
    end

    it 'some chars requiring URI escaping' do
      filename = 'escape_needed {} @#^ %|"`.ext'
      escaped_filename = ERB::Util.url_encode filename
      uri = "/file/oo000oo0000/#{escaped_filename}"
      expect(get: uri).to route_to(
        'file#show', id: 'oo000oo0000', file_name: filename)
    end

    it 'square brackets must be url escaped' do
      filename = 'foo[brackets].bar.pdf'
      escaped_filename = ERB::Util.url_encode filename
      expect(get: "/file/oo000oo0000/#{escaped_filename}").to route_to(
        'file#show', id: 'oo000oo0000', file_name: filename)
    end

    it 'question mark must be url escaped' do
      filename = 'foo?.pdf'
      escaped_filename = ERB::Util.url_encode filename
      expect(get: "/file/oo000oo0000/#{escaped_filename}").to route_to(
        'file#show', id: 'oo000oo0000', file_name: filename)
    end

    it 'ü must be url escaped' do
      skip('problem writing test:  ü decodes to \xC3\xBC')
      filename = "fü.pdf"
      escaped_filename = ERB::Util.url_encode(filename) # becomes %C3%BC
      expect(get: "/file/oo000oo0000/#{escaped_filename}").to route_to(
        'file#show', id: 'oo000oo0000', file_name: filename)
    end

    it '%20 in actual name (from ck155rf0207)' do
      skip('problem writing test:  %20 becomes space, over-aggressive param decoding?')
      filename = 'ARSCJ%202008.foo.bar.pdf'
      expect(get: "/file/oo000oo0000/#{ERB::Util.url_encode(filename)}").to route_to(
        'file#show', id: 'oo000oo0000', file_name: filename)
    end
  end

  describe 'authorization' do
    it 'routes to webauth#login_file' do
      expect(get: '/file/auth/oo000oo0000/def.pdf').to route_to('webauth#login_file', id: 'oo000oo0000', file_name: 'def.pdf')
    end

    it 'routes to webauth#login_file' do
      expect(get: '/file/app/oo000oo0000/def.pdf').to route_to('webauth#login_file', id: 'oo000oo0000', file_name: 'def.pdf')
    end
  end
end
