require 'rails_helper'

RSpec.describe "Authentication for Media requests", type: :request do

  context "#download" do
    context 'location' do
      let(:druid) { 'bb582xs1304' }
      let(:filename) { 'file' }
      let(:format) { 'mp4' }
      context 'not stanford qualified in any way' do
        it 'allows when user in location' do
          current_user = User.new(ip_address: 'ip.address1')
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).with('location1').and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)

          expect_any_instance_of(MediaController).to receive(:send_file).with(sms.path).and_call_original
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response.content_type).to eq('video/mp4')
        end
        it 'blocks when user not in location' do
          current_user = User.new
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          allow_any_instance_of(StacksMediaStream).to receive(:rights_xml)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return([false, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response).to have_http_status(403)
        end
      end
      context 'AND stanford' do
        it 'allows when user webauthed and in location' do
          current_user = User.new(webauth_user: true, ip_address: 'ip.address1')
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).with('location1').and_return([true, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)

          expect_any_instance_of(MediaController).to receive(:send_file).with(sms.path).and_call_original
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response.content_type).to eq('video/mp4')
        end
        it 'blocks when user webauthed but not in location' do
          current_user = User.new(webauth_user: true)
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          allow_any_instance_of(StacksMediaStream).to receive(:rights_xml)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return([false, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)

          get "/media/#{druid}/#{filename}.#{format}"
          expect(response).to have_http_status(403)
          # TODO: we may want to test that code goes through rescue_can_can
#          expect { get "/media/#{druid}/#{filename}/stream.#{format}" }.to raise_error(CanCan::AccessDenied)
        end
        it "prompts for webauth when user not webauthed but in location" do
          current_user = User.new(ip_address: 'ip.address1')
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          allow_any_instance_of(StacksMediaStream).to receive(:rights_xml)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).with('location1').and_return([true, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response).to redirect_to(auth_media_download_url(id: druid, file_name: filename, format: format))
        end
        it 'blocks when user not in location and not webauthed' do
          current_user = User.new
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          allow_any_instance_of(StacksMediaStream).to receive(:rights_xml)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return([false, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response).to have_http_status(403)
          # TODO: we may want to test that code goes through rescue_can_can
#          expect { get "/media/#{druid}/#{filename}/stream.#{format}" }.to raise_error(CanCan::AccessDenied)
        end
      end
      context 'OR stanford' do
        it 'allows when user webauthed and in location' do
          # this may be unnecessary or redundant
          current_user = User.new(webauth_user: true, ip_address: 'ip.address1')
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).with('location1').and_return([true, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)

          expect_any_instance_of(MediaController).to receive(:send_file).with(sms.path).and_call_original
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response.content_type).to eq('video/mp4')
        end
        it 'allows when user webauthed but not in location' do
          current_user = User.new(webauth_user: true)
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return([true, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)

          expect_any_instance_of(MediaController).to receive(:send_file).with(sms.path).and_call_original
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response.content_type).to eq('video/mp4')
        end
        it 'allows when user not webauthed but in location (no webauth prompt)' do
          current_user = User.new(ip_address: 'ip.address1')
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return([true, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)

          expect_any_instance_of(MediaController).to receive(:send_file).with(sms.path).and_call_original
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response.content_type).to eq('video/mp4')
        end
        it 'prompts for webauth when user not webauthed and not in location' do
          current_user = User.new
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow_any_instance_of(StacksMediaStream).to receive(:rights_xml)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return([false, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}.#{format}"
          expect(response).to redirect_to(auth_media_download_url(id: druid, file_name: filename, format: format))
        end
      end
    end
  end

  context '#stream' do
    context 'world-allowed' do
      it 'allows when user not webauthed' do
        skip("TODO: write this test")
      end
    end

    context 'stanford' do
      it 'allows when user webauthed' do
        skip("TODO: write this test")
      end
      it 'blocks when user not webauthed' do
        skip("TODO: write this test")
      end
      # TODO:  do we need to vary based on existence of location rights here?
    end

    context 'location' do
      let(:druid) { 'bb582xs1304' }
      let(:filename) { 'file.mp4' }
      let(:format) { 'm3u8' }
      context 'not stanford qualified in any way' do
        it 'allows when user in location' do
          current_user = User.new(ip_address: 'ip.address1')
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).with('location1').and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response.location).to match(%r{http://streaming-server.com.*})
        end
        it 'blocks when user not in location' do
          current_user = User.new
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          allow_any_instance_of(StacksMediaStream).to receive(:rights_xml)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return([false, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response).to have_http_status(403)
        end
      end
      context 'AND stanford' do
        it 'allows when user webauthed and in location' do
          current_user = User.new(webauth_user: true, ip_address: 'ip.address1')
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).with('location1').and_return([true, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response.location).to match(%r{http://streaming-server.com.*})
        end
        it 'blocks when user webauthed but not in location' do
          current_user = User.new(webauth_user: true)
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          allow_any_instance_of(StacksMediaStream).to receive(:rights_xml)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return([false, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response).to have_http_status(403)
          # TODO: we may want to test that code goes through rescue_can_can
#          expect { get "/media/#{druid}/#{filename}/stream.#{format}" }.to raise_error(CanCan::AccessDenied)
        end
        it "prompts for webauth when user not webauthed but in location" do
          current_user = User.new(ip_address: 'ip.address1')
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          allow_any_instance_of(StacksMediaStream).to receive(:rights_xml)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).with('location1').and_return([true, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response).to redirect_to(auth_media_stream_url(id: druid, file_name: filename, format: format))
        end
        it 'blocks when user not in location and not webauthed' do
          current_user = User.new
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          allow_any_instance_of(StacksMediaStream).to receive(:rights_xml)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return([false, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response).to have_http_status(403)
          # TODO: we may want to test that code goes through rescue_can_can
#          expect { get "/media/#{druid}/#{filename}/stream.#{format}" }.to raise_error(CanCan::AccessDenied)
        end
      end
      context 'OR stanford' do
        it 'allows when user webauthed and in location' do
          # this may be unnecessary or redundant
          current_user = User.new(webauth_user: true, ip_address: 'ip.address1')
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).with('location1').and_return([true, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response.location).to match(%r{http://streaming-server.com.*})
        end
        it 'allows when user webauthed but not in location' do
          current_user = User.new(webauth_user: true)
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return([true, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response.location).to match(%r{http://streaming-server.com.*})
        end
        it 'allows when user not webauthed but in location (no webauth prompt)' do
          current_user = User.new(ip_address: 'ip.address1')
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return([true, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response.location).to match(%r{http://streaming-server.com.*})
        end
        it 'prompts for webauth when user not webauthed and not in location' do
          current_user = User.new
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(current_user)
          allow_any_instance_of(StacksMediaStream).to receive(:rights_xml)
          sms = StacksMediaStream.new(id: druid, file_name: filename, format: format)
          allow(sms).to receive(:restricted_by_location?).and_return(true)
          allow(sms).to receive(:location_rights).and_return([false, ''])
          allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms)
          get "/media/#{druid}/#{filename}/stream.#{format}"
          expect(response).to redirect_to(auth_media_stream_url(id: druid, file_name: filename, format: format))
        end
      end
    end
  end
end
