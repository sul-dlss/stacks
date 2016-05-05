require 'rails_helper'

describe MediaController, vcr: { record: :new_episodes } do
  let(:video) { StacksMediaStream.new(id: 'bb582xs1304', file_name: 'bb582xs1304_sl', format: 'mp4') }

  describe '#download' do
    subject { get :download, id: 'bb582xs1304', file_name: 'bb582xs1304_sl', format: 'mp4' }

    it 'sends the video url to the user' do
      expect(controller).to receive(:send_file).with(video.path).and_call_original
      subject
    end

    it 'loads the video' do
      subject
      expect(assigns(:media)).to be_a StacksMediaStream
    end

    it 'sets the content type' do
      subject
      expect(controller.content_type).to eq 'video/mp4'
    end

    context 'additional params' do
      subject { get :download, id: 'xf680rd3068', file_name: 'xf680rd3068_1', format: 'mp4', ignored: 'a', host: 'b' }
      it 'ignored when instantiating StacksMediaStream' do
        subject
        expect { assigns(:media) }.not_to raise_exception
        expect(assigns(:media)).to be_a StacksMediaStream
      end
    end

    context 'for a missing file' do
      it 'returns a 404 Not Found' do
        allow(controller).to receive(:send_file).with(video.path).and_raise ActionController::MissingFile
        expect(subject.status).to eq 404
      end
    end

    context 'for a restricted file' do
      before do
        allow(controller).to receive(:authorize!).and_raise CanCan::AccessDenied
      end

      context 'with an authenticated user' do
        it 'fails for unauthorized user' do
          allow(controller).to receive(:current_user).and_return(User.new)
          expect(subject.status).to eq 403
        end
      end

      context 'with an unauthenticated user' do
        it 'redirects to the webauth login endpoint for media download' do
          expect(subject).to redirect_to auth_media_download_url(controller.params.symbolize_keys)
        end
        context 'additional params' do
          subject { get :download, id: 'xf680rd3068', file_name: 'xf680rd3068_1', format: 'mp4', ignored: 'ignored' }
          it 'ignored when redirecting' do
            expect(subject).not_to redirect_to(auth_media_download_url(controller.params.symbolize_keys))
            expect(subject).to redirect_to(auth_media_download_url(controller.send(:allowed_params).symbolize_keys))
            expect(subject).not_to redirect_to('/media/auth/xf680rd3068/xf680rd3068_1.mp4?ignored=ignored')
            expect(subject).to redirect_to('/media/auth/xf680rd3068/xf680rd3068_1.mp4')
          end
        end
      end
    end
  end

  describe '#stream' do
    let(:streaming_base_url) { Settings.stream.url }
    let(:token) { 'encrypted_token_value' }
    let(:streaming_url_query_str) { "token=#{token}" }
    subject { get :stream, id: 'bb582xs1304', file_name: 'bb582xs1304_sl.mp4', format: 'm3u8' }

    it 'redirects m3u8 format to streaming server mp4 prefix with playlist.m3u8' do
      allow(controller).to receive(:media_token).and_return token
      streaming_url_path = '/bb/582/xs/1304/mp4:bb582xs1304_sl.mp4/playlist.m3u8'
      expect(subject).to redirect_to "#{streaming_base_url}#{streaming_url_path}?#{streaming_url_query_str}"
    end
    it 'redirects mpd format to streaming server mp4 prefix with manifest.mpd' do
      allow(controller).to receive(:media_token).and_return token
      get :stream, id: 'bb582xs1304', file_name: 'bb582xs1304_sl.mp4', format: 'mpd'
      streaming_url_path = '/bb/582/xs/1304/mp4:bb582xs1304_sl.mp4/manifest.mpd'
      expect(response).to redirect_to "#{streaming_base_url}#{streaming_url_path}?#{streaming_url_query_str}"
    end

    context 'additional params' do
      subject { get :stream, id: 'xf680rd3068', file_name: 'file_1.mp4', format: 'm3u8', ignored: 'a', host: 'b' }
      it 'ignored when instantiating StacksMediaStream' do
        subject
        expect { assigns(:media) }.not_to raise_exception
        expect(assigns(:media)).to be_a StacksMediaStream
      end
    end

    context 'for a restricted file' do
      before do
        allow(controller).to receive(:authorize!).and_raise CanCan::AccessDenied
      end

      context 'with an authenticated user' do
        it 'fails for unauthorized user' do
          allow(controller).to receive(:current_user).and_return(User.new)
          expect(subject.status).to eq 403
        end
      end

      context 'with an unauthenticated user' do
        it 'redirects to the webauth login endpoint for media stream' do
          expect(subject).to redirect_to auth_media_stream_url(controller.params.symbolize_keys)
        end
        context 'additional params' do
          subject { get :stream, id: 'xf680rd3068', file_name: 'xf680rd3068_1.mp4', ignored: 'ignored' }
          it 'ignored when redirecting' do
            expect(subject).not_to redirect_to(auth_media_stream_url(controller.params.symbolize_keys))
            expect(subject).to redirect_to(auth_media_stream_url(controller.send(:allowed_params).symbolize_keys))
            expect(subject).not_to redirect_to('/media/auth/xf680rd3068/xf680rd3068_1.mp4/stream?ignored=ignored')
            expect(subject).to redirect_to('/media/auth/xf680rd3068/xf680rd3068_1.mp4/stream')
          end
        end
      end
    end
  end

  describe '#verify_token' do
    let(:id) { 'ab123cd4567' }
    let(:file_name) { 'interesting_video.mp4' }
    let(:ip_addr) { '192.168.1.100' }
    let(:token) { StacksMediaToken.new(id, file_name, ip_addr) }
    let(:encrypted_token) { token.to_encrypted_string }

    context 'mock #token_valid?' do
      it 'verifies a token when token_valid? returns true' do
        expect(controller).to receive(:token_valid?).with(encrypted_token, id, file_name, ip_addr).and_return true
        get :verify_token, token: encrypted_token, id: id, file_name: file_name, user_ip_addr: ip_addr
        expect(response.body).to eq 'valid token'
        expect(response.status).to eq 200
      end

      it 'rejects a token when token_valid? returns false' do
        expect(controller).to receive(:token_valid?).with(encrypted_token, id, file_name, ip_addr).and_return false
        get :verify_token, token: encrypted_token, id: id, file_name: file_name, user_ip_addr: ip_addr
        expect(response.body).to eq 'invalid token'
        expect(response.status).to eq 403
      end
    end

    context 'actually try to verify the token' do
      # these tests are a bit more integration-ish, since they actually end up calling
      # StacksMediaToken.verify_encrypted_token? instead of mocking the call to MediaController#token_valid?
      it 'verifies a valid token' do
        get :verify_token, token: encrypted_token, id: id, file_name: file_name, user_ip_addr: ip_addr
        expect(response.body).to eq 'valid token'
        expect(response.status).to eq 200
      end

      it 'rejects a token with a corrupted encrypted token string' do
        get :verify_token, token: "#{encrypted_token}aaaa", id: id, file_name: file_name, user_ip_addr: ip_addr
        expect(response.body).to eq 'invalid token'
        expect(response.status).to eq 403
      end

      it 'rejects a token for the wrong id' do
        get :verify_token, token: encrypted_token, id: 'zy098xv7654', file_name: file_name, user_ip_addr: ip_addr
        expect(response.body).to eq 'invalid token'
        expect(response.status).to eq 403
      end

      it 'rejects a token for the wrong file name' do
        get :verify_token, token: encrypted_token, id: id, file_name: 'some_other_file.mp3', user_ip_addr: ip_addr
        expect(response.body).to eq 'invalid token'
        expect(response.status).to eq 403
      end

      it 'rejects a token from the wrong IP address' do
        get :verify_token, token: encrypted_token, id: id, file_name: file_name, user_ip_addr: '192.168.1.101'
        expect(response.body).to eq 'invalid token'
        expect(response.status).to eq 403
      end

      it 'rejects a token that is too old' do
        expired_timestamp = (StacksMediaToken.max_token_age + 2.seconds).ago
        expect(token).to receive(:timestamp).and_return(expired_timestamp)
        get :verify_token, token: encrypted_token, id: id, file_name: file_name, user_ip_addr: '192.168.1.101'
        expect(response.body).to eq 'invalid token'
        expect(response.status).to eq 403
      end
    end
  end

  describe '#token_valid?' do
    it 'should call through to StacksMediaToken.verify_encrypted_token? and return the result' do
      expect(StacksMediaToken).to receive(:verify_encrypted_token?)
        .with('token', 'id', 'file_name', 'ip_addr').and_return(true)
      expect(controller.send(:token_valid?, 'token', 'id', 'file_name', 'ip_addr')).to eq true
    end
  end
end
