require 'rails_helper'

describe 'Media routes' do
  it 'download' do
    expect(get: '/media/oo000oo0000/aa666aa1234.mp4').to route_to(
      'media#download', id: 'oo000oo0000', file_name: 'aa666aa1234', format: 'mp4')
  end

  it 'download: filename with hyphen' do
    expect(get: '/media/oo000oo0000/aa666aa1234-a.mp4').to route_to(
      'media#download', id: 'oo000oo0000', file_name: 'aa666aa1234-a', format: 'mp4')
  end

  it 'stream: filename with format suffix' do
    expect(get: '/media/oo000oo0000/aa666aa1234.mp4/stream.m3u8').to route_to(
      'media#stream', id: 'oo000oo0000', file_name: 'aa666aa1234.mp4', format: 'm3u8')
    expect(get: '/media/oo000oo0000/aa666aa1234.mp4/stream.mpd').to route_to(
      'media#stream', id: 'oo000oo0000', file_name: 'aa666aa1234.mp4', format: 'mpd')
    expect(get: '/media/oo000oo0000/aa666aa1234.mov/stream.m3u8').to route_to(
      'media#stream', id: 'oo000oo0000', file_name: 'aa666aa1234.mov', format: 'm3u8')
  end

  it 'stream: filename with hyphen' do
    expect(get: '/media/oo000oo0000/aa666aa1234-a.mp4/stream.m3u8').to route_to(
      'media#stream', id: 'oo000oo0000', file_name: 'aa666aa1234-a.mp4', format: 'm3u8')
  end

  describe 'authorization' do
    it 'download routes to #login_media_download' do
      expect(get: '/media/auth/id/filename.mp4').to route_to(
        'webauth#login_media_download', id: 'id', file_name: 'filename', format: 'mp4')
    end
    it 'stream routes to #login_media_stream' do
      expect(get: '/media/auth/id/filename.mp4/stream.m3u8').to route_to(
        'webauth#login_media_stream', id: 'id', file_name: 'filename.mp4', format: 'm3u8')
    end
  end
end
