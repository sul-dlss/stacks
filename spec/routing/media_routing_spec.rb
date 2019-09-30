# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Media routes' do
  describe '#verify_token: filename with' do
    it 'chars not requiring URI escaping' do
      filename = "(no_escape_needed):;=&$*-_+!,~'.mp4"
      expect(get: "/media/oo000oo0000/#{filename}/verify_token").to route_to(
        'media#verify_token', id: 'oo000oo0000', file_name: filename)
    end

    it 'some chars requiring URI escaping' do
      filename = 'escape_needed {} @#^ %|"`.mp4'
      expect(get: "/media/oo000oo0000/#{ERB::Util.url_encode(filename)}/verify_token").to route_to(
        'media#verify_token', id: 'oo000oo0000', file_name: filename)
    end

    it 'multiple dots - all but last must be url escaped' do
      filename = 'foo.bar.foo.bar.mp4'
      escaped_filename = ERB::Util.url_encode filename
      expect(get: "/media/oo000oo0000/#{escaped_filename}/verify_token").to route_to(
        'media#verify_token', id: 'oo000oo0000', file_name: filename)
    end

    it 'square brackets must be url escaped' do
      filename = 'foo[brackets]bar.mp4'
      escaped_filename = ERB::Util.url_encode filename
      expect(get: "/media/oo000oo0000/#{escaped_filename}/verify_token").to route_to(
        'media#verify_token', id: 'oo000oo0000', file_name: filename)
    end

    it 'question mark must be url escaped' do
      filename = 'foo?.mp4'
      escaped_filename = ERB::Util.url_encode filename
      expect(get: "/media/oo000oo0000/#{escaped_filename}/verify_token").to route_to(
        'media#verify_token', id: 'oo000oo0000', file_name: filename)
    end

    it 'ü must be url escaped' do
      skip('problem writing test:  ü decodes to \xC3\xBC')
      filename = "fü.mp4"
      escaped_filename = ERB::Util.url_encode(filename) # becomes %C3%BC
      expect(get: "/media/oo000oo0000/#{escaped_filename}/verify_token").to route_to(
        'media#verify_token', id: 'oo000oo0000', file_name: filename)
    end

    it '%20 in actual name (from ck155rf0207)' do
      skip('problem writing test:  %20 becomes space, over-aggressive param decoding?')
      filename = 'ARSCJ%202008.foo.bar.mp4'
      expect(get: "/media/oo000oo0000/#{ERB::Util.url_encode(filename)}/verify_token").to route_to(
        'media#verify_token', id: 'oo000oo0000', file_name: filename)
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
