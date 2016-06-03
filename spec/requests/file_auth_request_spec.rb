require 'rails_helper'

RSpec.describe "Authentication for File requests", type: :request do

  let(:allowed_loc) { 'ip.address1' }
  let(:user_no_loc_no_webauth) { User.new }
  let(:user_loc_no_webauth) { User.new(ip_address: allowed_loc) }
  let(:user_webauth_no_stanford_no_loc) { User.new(webauth_user: true) }
  let(:user_webauth_stanford_no_loc) { User.new(webauth_user: true, ldap_groups: %w(stanford:stanford)) }
  let(:user_webauth_stanford_loc) { User.new(webauth_user: true, ldap_groups: %w(stanford:stanford), ip_address: allowed_loc) }
  let(:user_webauth_no_stanford_loc) { User.new(webauth_user: true, ip_address: allowed_loc) }
  let(:druid) { 'xf680rd3068' }
  let(:filename) { 'xf680rd3068_1.jp2' }

  context "#show" do
    let!(:sf_stanford_only) do
      sf = StacksFile.new(id: druid, file_name: filename)
      allow(sf).to receive(:stanford_only_rights).and_return([true, ''])
      allow(sf).to receive(:location_rights).and_return([false, ''])
      allow(sf).to receive(:restricted_by_location?).and_return(false)
      allow(sf).to receive(:agent_rights).and_return([false, ''])
      allow(sf).to receive(:world_rights).and_return([false, ''])
      allow(sf).to receive(:world_unrestricted?).and_return(false)
      sf
    end
    let!(:sf_loc_only) do
      sf = StacksFile.new(id: druid, file_name: filename)
      allow(sf).to receive(:restricted_by_location?).and_return(true)
      allow(sf).to receive(:location_rights).and_return([true, ''])
      allow(sf).to receive(:stanford_only_rights).and_return([false, ''])
      allow(sf).to receive(:agent_rights).and_return([false, ''])
      sf
    end
    let!(:sf_user_not_in_loc) do
      sf = StacksFile.new(id: druid, file_name: filename)
      allow(sf).to receive(:restricted_by_location?).and_return(true)
      allow(sf).to receive(:location_rights).and_return([false, ''])
      allow(sf).to receive(:stanford_only_rights).and_return([false, ''])
      allow(sf).to receive(:agent_rights).and_return([false, ''])
      sf
    end
    let!(:sf_loc_and_stanford) do
      sf = StacksFile.new(id: druid, file_name: filename)
      allow(sf).to receive(:stanford_only_rights).and_return([true, ''])
      allow(sf).to receive(:location_rights).and_return([true, ''])
      allow(sf).to receive(:restricted_by_location?).and_return(true)
      allow(sf).to receive(:agent_rights).and_return([false, ''])
      sf
    end
    let!(:sf_user_not_in_loc_and_stanford) do
      sf = StacksFile.new(id: druid, file_name: filename)
      allow(sf).to receive(:stanford_only_rights).and_return([true, ''])
      allow(sf).to receive(:restricted_by_location?).and_return(true)
      allow(sf).to receive(:location_rights).and_return([false, ''])
      allow(sf).to receive(:agent_rights).and_return([false, ''])
      sf
    end

    # NOTE:  stanford only + location rights tested under location context
    context 'stanford only (no location qualifications)' do
      context 'webauthed user' do
        it 'allows when user webauthed and authorized' do
          allow_any_instance_of(FileController).to receive(:current_user).and_return(user_webauth_stanford_no_loc)
          allow_any_instance_of(FileController).to receive(:current_file).and_return(sf_stanford_only)
          expect_any_instance_of(FileController).to receive(:send_file).with(sf_stanford_only.path).and_call_original
          get "/file/#{druid}/#{filename}"
        end
        it 'blocks when user webauthed but NOT authorized' do
          allow_any_instance_of(FileController).to receive(:current_user).and_return(user_webauth_no_stanford_no_loc)
          allow_any_instance_of(FileController).to receive(:current_file).and_return(sf_stanford_only)
          get "/file/#{druid}/#{filename}"
          expect(response).to have_http_status(403)
        end
      end
      it "prompts for webauth when user not webauthed" do
        allow_any_instance_of(FileController).to receive(:current_user).and_return(user_no_loc_no_webauth)
        allow_any_instance_of(FileController).to receive(:current_file).and_return(sf_stanford_only)
        get "/file/#{druid}/#{filename}"
        expect(response).to redirect_to(auth_file_url(id: druid, file_name: filename))
      end
    end
    context 'location' do
      context 'not stanford qualified in any way' do
        it 'allows when user in location' do
          allow_any_instance_of(FileController).to receive(:current_user).and_return(user_loc_no_webauth)
          allow_any_instance_of(FileController).to receive(:current_file).and_return(sf_loc_only)
          expect_any_instance_of(FileController).to receive(:send_file).with(sf_loc_only.path).and_call_original
          get "/file/#{druid}/#{filename}"
        end
        it 'blocks when user not in location' do
          allow_any_instance_of(FileController).to receive(:current_user).and_return(user_no_loc_no_webauth)
          allow_any_instance_of(FileController).to receive(:current_file).and_return(sf_user_not_in_loc)
          get "/file/#{druid}/#{filename}"
          expect(response).to have_http_status(403)
        end
      end
      context 'OR stanford' do
        context 'user webauthed' do
          context 'authorized' do
            it 'allows when user in location' do
              allow_any_instance_of(FileController).to receive(:current_user).and_return(user_webauth_stanford_loc)
              allow_any_instance_of(FileController).to receive(:current_file).and_return(sf_loc_and_stanford)
              expect_any_instance_of(FileController).to receive(:send_file).with(sf_loc_and_stanford.path).and_call_original
              get "/file/#{druid}/#{filename}"
            end
            it 'allows when user not in location' do
              allow_any_instance_of(FileController).to receive(:current_user).and_return(user_webauth_stanford_no_loc)
              allow_any_instance_of(FileController).to receive(:current_file).and_return(sf_user_not_in_loc_and_stanford)
              expect_any_instance_of(FileController).to receive(:send_file).with(sf_user_not_in_loc_and_stanford.path).and_call_original
              get "/file/#{druid}/#{filename}"
            end
          end
          context 'NOT authorized' do
            it 'allows when in location' do
              allow_any_instance_of(FileController).to receive(:current_user).and_return(user_webauth_no_stanford_loc)
              allow_any_instance_of(FileController).to receive(:current_file).and_return(sf_loc_and_stanford)
              expect_any_instance_of(FileController).to receive(:send_file).with(sf_loc_and_stanford.path).and_call_original
              get "/file/#{druid}/#{filename}"
            end
            it 'blocks when not in location' do
              allow_any_instance_of(FileController).to receive(:current_user).and_return(user_webauth_no_stanford_no_loc)
              allow_any_instance_of(FileController).to receive(:current_file).and_return(sf_user_not_in_loc_and_stanford)
              get "/file/#{druid}/#{filename}"
              expect(response).to have_http_status(403)
            end
          end
        end
        context 'user NOT webauthed' do
          it 'allows when in location (no webauth prompt)' do
            allow_any_instance_of(FileController).to receive(:current_user).and_return(user_loc_no_webauth)
            allow_any_instance_of(FileController).to receive(:current_file).and_return(sf_loc_and_stanford)
            expect_any_instance_of(FileController).to receive(:send_file).with(sf_loc_and_stanford.path).and_call_original
            get "/file/#{druid}/#{filename}"
          end
          it 'prompts for webauth when not in location' do
            allow_any_instance_of(FileController).to receive(:current_user).and_return(user_no_loc_no_webauth)
            allow_any_instance_of(FileController).to receive(:current_file).and_return(sf_user_not_in_loc_and_stanford)
            get "/file/#{druid}/#{filename}"
            expect(response).to redirect_to(auth_file_url(id: druid, file_name: filename))
          end
        end
      end
    end
  end
end