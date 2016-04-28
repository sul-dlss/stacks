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
    subject { get :stream, id: 'bb582xs1304', file_name: 'bb582xs1304_sl.mp4', format: 'm3u8' }

    it 'redirects m3u8 format to streaming server mp4 prefix with playlist.m3u8' do
      expect(subject).to redirect_to "#{streaming_base_url}/bb/582/xs/1304/mp4:bb582xs1304_sl.mp4/playlist.m3u8"
    end
    it 'redirects mpd format to streaming server mp4 prefix with manifest.mpd' do
      get :stream, id: 'bb582xs1304', file_name: 'bb582xs1304_sl.mp4', format: 'mpd'
      expect(response).to redirect_to "#{streaming_base_url}/bb/582/xs/1304/mp4:bb582xs1304_sl.mp4/manifest.mpd"
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
end
