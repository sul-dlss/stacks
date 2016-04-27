require 'rails_helper'

describe StacksMediaStream do
  let(:streaming_base_url) { Settings.stream.url }

  # it 'should be the pairtree path to the media manifest (hls)' do
  # expect(subject.path).to eq "#{streaming_base_url}/ab/012/cd/3456/mp4:def.mp4/playlist.m3u8"

  describe '#to_playlist_url' do
    context 'video' do
      it 'mp4 extension' do
        sms = described_class.new(id: 'druid:ab012cd3456', file_name: 'def.mp4', format: 'ignored')
        expect(sms.to_playlist_url).to eq "#{streaming_base_url}/ab/012/cd/3456/mp4:def.mp4/playlist.m3u8"
      end
      it 'mov extension' do
        sms = described_class.new(id: 'druid:ab012cd3456', file_name: 'def.mov', format: 'ignored')
        expect(sms.to_playlist_url).to eq "#{streaming_base_url}/ab/012/cd/3456/mp4:def.mov/playlist.m3u8"
      end
    end
    it 'audio - mp3' do
      sms = described_class.new(id: 'druid:ab012cd3456', file_name: 'def.mp3', format: 'ignored')
      expect(sms.to_playlist_url).to eq "#{streaming_base_url}/ab/012/cd/3456/mp3:def.mp3/playlist.m3u8"
    end
    it 'unknown' do
      sms = described_class.new(id: 'druid:ab012cd3456', file_name: 'def.xxx', format: 'ignored')
      expect(sms.to_playlist_url).to be_nil
    end
  end

  describe '#to_manifest_url' do
    context 'video' do
      it 'mp4 extension' do
        sms = described_class.new(id: 'druid:ab012cd3456', file_name: 'def.mp4', format: 'ignored')
        expect(sms.to_manifest_url).to eq "#{streaming_base_url}/ab/012/cd/3456/mp4:def.mp4/manifest.mpd"
      end
      it 'mov extension' do
        sms = described_class.new(id: 'druid:ab012cd3456', file_name: 'def.mov', format: 'ignored')
        expect(sms.to_manifest_url).to eq "#{streaming_base_url}/ab/012/cd/3456/mp4:def.mov/manifest.mpd"
      end
    end
    it 'audio - mp3' do
      sms = described_class.new(id: 'druid:ab012cd3456', file_name: 'def.mp3', format: 'ignored')
      expect(sms.to_manifest_url).to eq "#{streaming_base_url}/ab/012/cd/3456/mp3:def.mp3/manifest.mpd"
    end
    it 'unknown' do
      sms = described_class.new(id: 'druid:ab012cd3456', file_name: 'def.xxx', format: 'ignored')
      expect(sms.to_manifest_url).to be_nil
    end
    it 'missing file_name' do
      sms = described_class.new(id: 'druid:ab012cd3456', format: 'ignored')
      expect(sms.to_manifest_url).to be_nil
    end
  end
end
