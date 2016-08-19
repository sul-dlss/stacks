require 'rails_helper'

describe 'Media routes' do
  it 'download' do
    expect(get: '/media/oo000oo0000/aa666aa1234.mp4').to route_to(
      'media#download', id: 'oo000oo0000', file_name: 'aa666aa1234', format: 'mp4')
  end

  context '#download: filename with' do
    it 'chars not requiring URI escaping' do
      filename = "(no_escape_needed):;=&$*-_+!,~'"
      expect(get: "/media/oo000oo0000/#{filename}.mp4").to route_to(
        'media#download', id: 'oo000oo0000', file_name: filename, format: 'mp4')
    end

    it 'some chars requiring URI escaping' do
      filename = 'escape_needed {} @#^ %|"`'
      expect(get: "/media/oo000oo0000/#{URI.escape(filename)}.mp4").to route_to(
        'media#download', id: 'oo000oo0000', file_name: filename, format: 'mp4')
    end

    it 'multiple dots - all but last must be url escaped' do
      filename = 'foo.bar.foo.bar'
      escaped_filename = 'foo%2Ebar%2Efoo%2Ebar' # URI.escape doesn't do periods
      expect(get: "/media/oo000oo0000/#{escaped_filename}.mp4").to route_to(
        'media#download', id: 'oo000oo0000', file_name: filename, format: 'mp4')
    end

    it 'square brackets must be url escaped' do
      filename = 'foo[brackets]bar'
      escaped_filename = 'foo%5Bbrackets%5Dbar' # URI.escape doesn't do square brackets
      expect(get: "/media/oo000oo0000/#{escaped_filename}.mp4").to route_to(
        'media#download', id: 'oo000oo0000', file_name: filename, format: 'mp4')
    end

    it 'question mark must be url escaped' do
      filename = 'foo?'
      escaped_filename = 'foo%3F' # URI.escape doesn't do question mark
      expect(get: "/media/oo000oo0000/#{escaped_filename}.mp4").to route_to(
        'media#download', id: 'oo000oo0000', file_name: filename, format: 'mp4')
    end

    it 'ü must be url escaped' do
      skip('problem writing test:  ü decodes to \xC3\xBC')
      filename = "fü"
      escaped_filename = URI.escape(filename) # becomes %C3%BC
      expect(get: "/media/oo000oo0000/#{escaped_filename}.mp4").to route_to(
        'media#download', id: 'oo000oo0000', file_name: filename, format: 'mp4')
    end

    it '%20 in actual name (from ck155rf0207)' do
      skip('problem writing test:  %20 becomes space, over-aggressive param decoding?')
      filename = 'ARSCJ%202008.foo.bar'
      expect(get: "/media/oo000oo0000/#{URI.escape(filename)}.mp4").to route_to(
        'media#download', id: 'oo000oo0000', file_name: filename, format: 'mp4')
    end
  end

  describe 'authorization' do
    it 'download routes to #login_media_download' do
      expect(get: '/media/auth/id/filename.mp4').to route_to(
        'webauth#login_media_download', id: 'id', file_name: 'filename', format: 'mp4')
    end
  end

  it 'verify_token' do
    expect(get: '/media/id/filename.mp4/verify_token?stacks_token=asdf&user_ip=192.168.1.100').to route_to(
      'media#verify_token', id: 'id', file_name: 'filename.mp4', stacks_token: 'asdf', user_ip: '192.168.1.100')
  end

  it 'auth_check' do
    expect(get: '/media/id/filename.mp4/auth_check').to route_to(
      'media#auth_check', id: 'id', file_name: 'filename.mp4'
    )
  end
end
