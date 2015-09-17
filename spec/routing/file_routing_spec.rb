require 'rails_helper'

describe 'file routes' do
  it 'routes to #show' do
    expect(get: '/file/abc/def.pdf').to route_to('file#show', id: 'abc', file_name: 'def.pdf')
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