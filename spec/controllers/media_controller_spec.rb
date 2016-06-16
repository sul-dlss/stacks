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
  end

  describe '#stream' do
    let(:streaming_base_url) { Settings.stream.url }
    let(:encrypted_token) { 'encrypted_token_value' }
    let(:streaming_url_query_str) { "stacks_token=#{encrypted_token}" }
    subject { get :stream, id: 'bb582xs1304', file_name: 'bb582xs1304_sl.mp4', format: 'm3u8' }

    it 'redirects m3u8 format to streaming server mp4 prefix with playlist.m3u8' do
      allow(controller).to receive(:encrypted_token).and_return encrypted_token
      streaming_url_path = '/bb/582/xs/1304/mp4:bb582xs1304_sl.mp4/playlist.m3u8'
      expect(subject).to redirect_to "#{streaming_base_url}#{streaming_url_path}?#{streaming_url_query_str}"
    end
    it 'redirects mpd format to streaming server mp4 prefix with manifest.mpd' do
      allow(controller).to receive(:encrypted_token).and_return encrypted_token
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
        get :verify_token, stacks_token: encrypted_token, id: id, file_name: file_name, user_ip: ip_addr
        expect(response.body).to eq 'valid token'
        expect(response.status).to eq 200
      end

      it 'rejects a token when token_valid? returns false' do
        expect(controller).to receive(:token_valid?).with(encrypted_token, id, file_name, ip_addr).and_return false
        get :verify_token, stacks_token: encrypted_token, id: id, file_name: file_name, user_ip: ip_addr
        expect(response.body).to eq 'invalid token'
        expect(response.status).to eq 403
      end
    end

    context 'actually try to verify the token' do
      # these tests are a bit more integration-ish, since they actually end up calling
      # StacksMediaToken.verify_encrypted_token? instead of mocking the call to MediaController#token_valid?
      it 'verifies a valid token' do
        get :verify_token, stacks_token: encrypted_token, id: id, file_name: file_name, user_ip: ip_addr
        expect(response.body).to eq 'valid token'
        expect(response.status).to eq 200
      end

      it 'rejects a token with a corrupted encrypted token string' do
        get :verify_token, stacks_token: "#{encrypted_token}aaaa", id: id, file_name: file_name, user_ip: ip_addr
        expect(response.body).to eq 'invalid token'
        expect(response.status).to eq 403
      end

      it 'rejects a token for the wrong id' do
        get :verify_token, stacks_token: encrypted_token, id: 'zy098xv7654', file_name: file_name, user_ip: ip_addr
        expect(response.body).to eq 'invalid token'
        expect(response.status).to eq 403
      end

      it 'rejects a token for the wrong file name' do
        get :verify_token, stacks_token: encrypted_token, id: id, file_name: 'some_other_file.mp3', user_ip: ip_addr
        expect(response.body).to eq 'invalid token'
        expect(response.status).to eq 403
      end

      it 'rejects a token from the wrong IP address' do
        get :verify_token, stacks_token: encrypted_token, id: id, file_name: file_name, user_ip: '192.168.1.101'
        expect(response.body).to eq 'invalid token'
        expect(response.status).to eq 403
      end

      it 'rejects a token that is too old' do
        expired_timestamp = (StacksMediaToken.max_token_age + 2.seconds).ago
        expect(token).to receive(:timestamp).and_return(expired_timestamp)
        get :verify_token, stacks_token: encrypted_token, id: id, file_name: file_name, user_ip: '192.168.1.101'
        expect(response.body).to eq 'invalid token'
        expect(response.status).to eq 403
      end
    end
  end

  describe '#token_valid?' do
    it 'should call through to StacksMediaToken.verify_encrypted_token? and return the result' do
      expect(StacksMediaToken).to receive(:verify_encrypted_token?)
        .with('stacks_token', 'id', 'file_name', 'ip_addr').and_return(true)
      expect(controller.send(:token_valid?, 'stacks_token', 'id', 'file_name', 'ip_addr')).to eq true
    end
  end

  describe '#auth_check' do
    let(:id) { 'abc123' }
    let(:file_name) { 'some_file.mp4' }

    it 'returns JSON from hash_for_auth_check' do
      test_hash = { foo: :bar }
      expect(controller).to receive(:hash_for_auth_check).and_return(test_hash)
      get :auth_check, id: id, file_name: file_name, format: :js
      body = JSON.parse(response.body)
      expect(body).to eq('foo' => 'bar')
    end

    context 'success' do
      before { allow(controller).to receive(:can?).and_return(true) }
      it 'returns json that indicates a successful auth check' do
        get :auth_check, id: id, file_name: file_name, format: :js
        body = JSON.parse(response.body)
        expect(body).to eq('status' => 'success')
      end
    end
  end

  describe '#hash_for_auth_check' do
    context 'cancan authorizes' do
      before { allow(controller).to receive(:can?).and_return(true) }
      it 'returns hash with status of success' do
        expect(controller.send(:hash_for_auth_check)).to eq(status: :success)
      end
    end
    context 'cancan does NOT authorize' do
      context "stanford restricted, no location restriction, and user not webauthed" do
        before(:each) do
          allow(controller).to receive(:can?).and_return(false)
          sms = double('StacksMediaStream')
          allow(sms).to receive(:stanford_only_rights).and_return(true, '')
          allow(sms).to receive(:restricted_by_location?).and_return(false)
          allow(sms).to receive(:location_rights).and_return(false)
          allow(controller).to receive(:current_media).and_return sms
        end
        it 'hash with status :must_authenticate' do
          expect(controller.send(:hash_for_auth_check)[:status]).to eq :must_authenticate
        end
        it 'hash indicates where/if the user can authenticate' do
          result_hash = controller.send(:hash_for_auth_check)
          expect(result_hash).to have_key(:service)
          expect(result_hash[:service]['@id']).to match(/^https?:/)
          expect(result_hash[:service]['label']).to eq 'Stanford-affiliated? Login to play'
        end
      end
      context 'location restricted, no stanford restriction' do
        before(:each) do
          allow(controller).to receive(:can?).and_return(false)
          sms = double('StacksMediaStream')
          allow(sms).to receive(:stanford_only_rights).and_return(false, '')
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return(false) # user not in loc
          allow(controller).to receive(:current_media).and_return sms
        end
        it 'hash with status :location_restricted' do
          expect(controller.send(:hash_for_auth_check)[:status]).to eq :location_restricted
        end
        it 'hash indicates where to find location info' do
          messages = controller.send(:hash_for_auth_check)['label']
          expect(messages.size).to eq 2
          expect(messages[0]).to eq 'Restricted media cannot be played in your location.'
          expect(messages[1]).to eq 'See Access conditions for more information.'
        end
      end
      context 'location restrictions and stanford restriction on current_media' do
        before(:each) do
          allow(controller).to receive(:can?).and_return(false)
          sms = double('StacksMediaStream')
          allow(sms).to receive(:stanford_only_rights).and_return(true, '')
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return(false) # user not in loc
          allow(controller).to receive(:current_media).and_return sms
        end
        it 'hash with status :stanford_restricted, :location_restricted' do
          status = controller.send(:hash_for_auth_check)[:status]
          expect(status.size).to eq 2
          expect(status[0]).to eq :stanford_restricted
          expect(status[1]).to eq :location_restricted
        end
        it 'hash has where/if the user can authenticate' do
          result_hash = controller.send(:hash_for_auth_check)
          expect(result_hash).to have_key(:service)
          expect(result_hash[:service]['@id']).to match(/^https?:/)
          expect(result_hash[:service]['label']).to eq 'Stanford-affiliated? Login to play'
        end
        it 'hash indicates where to find location info' do
          messages = controller.send(:hash_for_auth_check)['label']
          expect(messages.size).to eq 2
          expect(messages[0]).to eq 'Limited access for non-Stanford guests.'
          expect(messages[1]).to eq 'See Access conditions for more information.'
        end
      end
    end
  end
end
