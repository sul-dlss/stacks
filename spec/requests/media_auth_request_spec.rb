require 'rails_helper'

RSpec.describe "Authentication for Media requests", type: :request do

  let(:allowed_loc) { 'ip.address1' }
  let(:user_no_loc_no_webauth) { User.new }
  let(:user_no_loc_webauth) { User.new(webauth_user: true) }
  let(:user_loc_no_webauth) { User.new(ip_address: allowed_loc) }
  let(:user_webauth_no_stanford_no_loc) { User.new(webauth_user: true) }
  let(:user_webauth_stanford_no_loc) { User.new(webauth_user: true, ldap_groups: %w(stanford:stanford)) }
  let(:user_webauth_stanford_loc) { User.new(webauth_user: true, ldap_groups: %w(stanford:stanford), ip_address: allowed_loc) }
  let(:user_webauth_no_stanford_loc) { User.new(webauth_user: true, ip_address: allowed_loc) }
  let(:druid) { 'bb582xs1304' }

  context "#download" do
    let(:filename) { 'file' }
    let(:format) { 'mp4' }
    let!(:sms_stanford_only) do
      sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
      allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
      allow(sms).to receive(:restricted_by_location?).and_return(false)
      allow(sms).to receive(:location_rights).and_return([false, ''])
      allow(sms).to receive(:agent_rights).and_return([false, ''])
      allow(sms).to receive(:world_unrestricted?).and_return(false)
      allow(sms).to receive(:world_rights).and_return([false, ''])
      sms
    end
    let!(:sms_location_only) do
      sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
      allow(sms).to receive(:restricted_by_location?).and_return(true)
      allow(sms).to receive(:location_rights).and_return([true, ''])
      sms
    end
    let!(:sms_user_not_in_loc) do
      sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
      allow(sms).to receive(:restricted_by_location?).and_return(true)
      allow(sms).to receive(:location_rights).and_return([false, ''])
      allow(sms).to receive(:stanford_only_rights).and_return([false, ''])
      allow(sms).to receive(:agent_rights).and_return([false, ''])
      sms
    end
    let!(:sms_loc_and_stanford) do
      sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
      allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
      allow(sms).to receive(:restricted_by_location?).and_return(true)
      allow(sms).to receive(:location_rights).and_return([true, ''])
      sms
    end
    let!(:sms_user_not_in_loc_and_stanford) do
      sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
      allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
      allow(sms).to receive(:restricted_by_location?).and_return(true)
      allow(sms).to receive(:location_rights).and_return([false, ''])
      allow(sms).to receive(:agent_rights).and_return([false, ''])
      sms
    end
    # NOTE:  stanford only + location rights tested under location context
    context 'stanford only (no location qualifications)' do
      context 'webauthed user' do
        it 'allows when user webauthed and authorized' do
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_stanford_no_loc)
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_stanford_only)
          expect_any_instance_of(MediaController).to receive(:send_file).with(sms_stanford_only.path).and_call_original
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response.content_type).to eq('video/mp4')
        end
        it 'blocks when user webauthed but NOT authorized' do
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_no_stanford_no_loc)
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_stanford_only)
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response).to have_http_status(403)
        end
      end
      it "prompts for webauth when user not webauthed and not in loc" do
        allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_no_loc_no_webauth)
        allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_stanford_only)
        get "/media/#{druid}/#{filename}.#{format}"
        expect(response).to redirect_to(auth_media_download_url(id: druid, file_name: filename, format: format))
      end
      it "prompts for webauth when user not webauthed and in loc" do
        allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_loc_no_webauth)
        allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_stanford_only)
        get "/media/#{druid}/#{filename}.#{format}"
        expect(response).to redirect_to(auth_media_download_url(id: druid, file_name: filename, format: format))
      end
    end
    context 'location' do
      context 'not stanford qualified in any way' do
        it 'allows when user in location' do
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_loc_no_webauth)
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_location_only)
          expect_any_instance_of(MediaController).to receive(:send_file).with(sms_location_only.path).and_call_original
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response.content_type).to eq('video/mp4')
        end
        it 'blocks when user not in location' do
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_no_loc_webauth)
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_user_not_in_loc)
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response).to have_http_status(403)
        end
      end
      context 'OR stanford' do
        context 'user webauthed' do
          context 'authorized' do
            it 'allows when user in location' do
              allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_stanford_loc)
              allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_loc_and_stanford)
              expect_any_instance_of(MediaController).to receive(:send_file).with(sms_loc_and_stanford.path).and_call_original
              get "/media/#{druid}/#{filename}.#{format}"
              expect(response.content_type).to eq('video/mp4')
            end
            it 'allows when user not in location' do
              allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_stanford_no_loc)
              allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_user_not_in_loc_and_stanford)
              expect_any_instance_of(MediaController).to receive(:send_file).with(sms_user_not_in_loc_and_stanford.path).and_call_original
              get "/media/#{druid}/#{filename}.#{format}"
              expect(response.content_type).to eq('video/mp4')
            end
          end
          context 'NOT authorized' do
            it 'allows when in location' do
              allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_no_stanford_loc)
              allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_loc_and_stanford)
              expect_any_instance_of(MediaController).to receive(:send_file).with(sms_loc_and_stanford.path).and_call_original
              get "/media/#{druid}/#{filename}.#{format}"
              expect(response.content_type).to eq('video/mp4')
            end
            it 'blocks when not in location' do
              allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_no_stanford_no_loc)
              allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_user_not_in_loc_and_stanford)
              get "/media/#{druid}/#{filename}.#{format}"
              expect(response).to have_http_status(403)
            end
          end
        end
        context 'user NOT webauthed' do
          it 'allows when in location (no webauth prompt)' do
            allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_loc_no_webauth)
            allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_loc_and_stanford)
            expect_any_instance_of(MediaController).to receive(:send_file).with(sms_loc_and_stanford.path).and_call_original
            get "/media/#{druid}/#{filename}.#{format}"
            expect(response.content_type).to eq('video/mp4')
          end
          it 'prompts for webauth when not in location' do
            allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_no_loc_no_webauth)
            allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_user_not_in_loc_and_stanford)
            get "/media/#{druid}/#{filename}.#{format}"
            expect(response).to redirect_to(auth_media_download_url(id: druid, file_name: filename, format: format))
          end
        end
      end
    end
  end

  context '#stream' do
    let(:filename) { 'file.mp4' }
    let(:format) { 'm3u8' }
    let!(:sms_stanford_only) do
      sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
      allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
      allow(sms).to receive(:restricted_by_location?).and_return(false)
      allow(sms).to receive(:location_rights).and_return([false, ''])
      allow(sms).to receive(:agent_rights).and_return([false, ''])
      allow(sms).to receive(:world_unrestricted?).and_return(false)
      allow(sms).to receive(:world_rights).and_return([false, ''])
      sms
    end
    let!(:sms_location_only) do
      sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
      allow(sms).to receive(:restricted_by_location?).and_return(true)
      allow(sms).to receive(:location_rights).and_return([true, ''])
      sms
    end
    let!(:sms_user_not_in_loc) do
      sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
      allow(sms).to receive(:restricted_by_location?).and_return(true)
      allow(sms).to receive(:location_rights).and_return([false, ''])
      allow(sms).to receive(:stanford_only_rights).and_return([false, ''])
      allow(sms).to receive(:agent_rights).and_return([false, ''])
      sms
    end
    let!(:sms_loc_and_stanford) do
      sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
      allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
      allow(sms).to receive(:restricted_by_location?).and_return(true)
      allow(sms).to receive(:location_rights).and_return([true, ''])
      sms
    end
    let!(:sms_user_not_in_loc_and_stanford) do
      sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
      allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
      allow(sms).to receive(:restricted_by_location?).and_return(true)
      allow(sms).to receive(:location_rights).and_return([false, ''])
      allow(sms).to receive(:agent_rights).and_return([false, ''])
      sms
    end
    # NOTE:  stanford only + location rights tested under location context
    context 'stanford only (no location qualifications)' do
      context 'webauthed user' do
        it 'allows when user webauthed and authorized' do
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_stanford_no_loc)
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_stanford_only)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response.location).to match(%r{http://streaming-server.com.*})
        end
        it 'blocks when user webauthed but NOT authorized' do
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_no_stanford_no_loc)
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_stanford_only)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response).to have_http_status(403)
        end
      end
      it "prompts for webauth when user not webauthed" do
        allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_loc_no_webauth)
        allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_stanford_only)
        get "/media/#{druid}/#{filename}/stream.#{format}"
        expect(response).to redirect_to(auth_media_stream_url(id: druid, file_name: filename, format: format))
      end
    end
    context 'location' do
      context 'not stanford qualified in any way' do
        it 'allows when user in location' do
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_loc_no_webauth)
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_location_only)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response.location).to match(%r{http://streaming-server.com.*})
        end
        it 'blocks when user not in location' do
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_no_loc_no_webauth)
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_user_not_in_loc)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response).to have_http_status(403)
        end
      end
      context 'OR stanford' do
        context 'user webauthed' do
          context 'authorized' do
            it 'allows when user in location' do
              allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_stanford_loc)
              allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_loc_and_stanford)
              get "/media/#{druid}/#{filename}/stream.#{format}"
              expect(response.location).to match(%r{http://streaming-server.com.*})
            end
            it 'allows when user not in location' do
              allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_stanford_no_loc)
              allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_user_not_in_loc_and_stanford)
              get "/media/#{druid}/#{filename}/stream.#{format}"
              expect(response.location).to match(%r{http://streaming-server.com.*})
            end
          end
          context 'NOT authorized' do
            it 'allows when in location' do
              allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_no_stanford_loc)
              allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_loc_and_stanford)
              get "/media/#{druid}/#{filename}/stream.#{format}"
              expect(response.location).to match(%r{http://streaming-server.com.*})
            end
            it 'blocks when not in location' do
              allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_no_stanford_no_loc)
              allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_user_not_in_loc_and_stanford)
              get "/media/#{druid}/#{filename}/stream.#{format}"
              expect(response).to have_http_status(403)
            end
          end
        end
        context 'user NOT webauthed' do
          it 'allows when in location (no webauth prompt)' do
            allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_loc_no_webauth)
            allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_loc_and_stanford)
            get "/media/#{druid}/#{filename}/stream.#{format}"
            expect(response.location).to match(%r{http://streaming-server.com.*})
          end
          it 'prompts for webauth when not in location' do
            allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_no_loc_no_webauth)
            allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_user_not_in_loc_and_stanford)
            get "/media/#{druid}/#{filename}/stream.#{format}"
            expect(response).to redirect_to(auth_media_stream_url(id: druid, file_name: filename, format: format))
          end
        end
      end
    end
  end
end
