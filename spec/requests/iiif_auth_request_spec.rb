require 'rails_helper'

RSpec.describe "Authentication for IIIF requests", type: :request do

  let(:allowed_loc) { 'ip.address1' }
  let(:user_no_loc_no_webauth) { User.new }
  let(:user_loc_no_webauth) { User.new(ip_address: allowed_loc) }
  let(:user_webauth_no_stanford_no_loc) { User.new(webauth_user: true) }
  let(:user_webauth_stanford_no_loc) { User.new(webauth_user: true, ldap_groups: %w(stanford:stanford)) }
  let(:user_webauth_stanford_loc) { User.new(webauth_user: true, ldap_groups: %w(stanford:stanford), ip_address: allowed_loc) }
  let(:user_webauth_no_stanford_loc) { User.new(webauth_user: true, ip_address: allowed_loc) }
  let(:identifier) { 'nr349ct7889%2Fnr349ct7889_00_0001' }
  let(:druid) { 'nr349ct7889' }
  let(:filename) { 'nr349ct7889_00_0001' }
  let(:region) { '0,640,2552,2552' }
  let(:size) { '100,100' }
  let(:rotation) { '0' }
  let(:quality) { 'default' }
  let(:format) { 'jpg' }
  let(:params_hash) { { id: druid, file_name: filename, region: region, size: size, rotation: rotation, quality: quality, format: format } }

  context "#show" do
    let!(:si_stanford_only) do
      si = StacksImage.new(params_hash)
      allow(si).to receive(:stanford_only_rights).and_return([true, ''])
      allow(si).to receive(:location_rights).and_return([false, ''])
      allow(si).to receive(:restricted_by_location?).and_return(false)
      allow(si).to receive(:agent_rights).and_return([false, ''])
      allow(si).to receive(:world_rights).and_return([false, ''])
      allow(si).to receive(:world_unrestricted?).and_return(false)
      allow(si).to receive(:valid?).and_return(true)
      allow(si).to receive(:exist?).and_return(true)
      allow(si).to receive(:url).and_return("url")
      si
    end
    let!(:si_loc_only) do
      si = StacksImage.new(params_hash)
      allow(si).to receive(:restricted_by_location?).and_return(true)
      allow(si).to receive(:location_rights).and_return([true, ''])
      allow(si).to receive(:stanford_only_rights).and_return([false, ''])
      allow(si).to receive(:agent_rights).and_return([false, ''])
      allow(si).to receive(:world_rights).and_return([false, ''])
      allow(si).to receive(:valid?).and_return(true)
      allow(si).to receive(:exist?).and_return(true)
      allow(si).to receive(:url).and_return("url")
      si
    end
    let!(:si_user_not_in_loc) do
      si = StacksImage.new(params_hash)
      allow(si).to receive(:restricted_by_location?).and_return(true)
      allow(si).to receive(:location_rights).and_return([false, ''])
      allow(si).to receive(:stanford_only_rights).and_return([false, ''])
      allow(si).to receive(:agent_rights).and_return([false, ''])
      allow(si).to receive(:world_rights).and_return([false, ''])
      allow(si).to receive(:valid?).and_return(true)
      allow(si).to receive(:exist?).and_return(true)
      allow(si).to receive(:url).and_return("url")
      si
    end
    let!(:si_loc_and_stanford) do
      si = StacksImage.new(params_hash)
      allow(si).to receive(:stanford_only_rights).and_return([true, ''])
      allow(si).to receive(:location_rights).and_return([true, ''])
      allow(si).to receive(:restricted_by_location?).and_return(true)
      allow(si).to receive(:agent_rights).and_return([false, ''])
      allow(si).to receive(:world_rights).and_return([false, ''])
      allow(si).to receive(:valid?).and_return(true)
      allow(si).to receive(:exist?).and_return(true)
      allow(si).to receive(:url).and_return("url")
      si
    end
    let!(:si_user_not_in_loc_and_stanford) do
      si = StacksImage.new(params_hash)
      allow(si).to receive(:stanford_only_rights).and_return([true, ''])
      allow(si).to receive(:restricted_by_location?).and_return(true)
      allow(si).to receive(:location_rights).and_return([false, ''])
      allow(si).to receive(:agent_rights).and_return([false, ''])
      allow(si).to receive(:world_rights).and_return([false, ''])
      allow(si).to receive(:valid?).and_return(true)
      allow(si).to receive(:exist?).and_return(true)
      allow(si).to receive(:url).and_return("url")
      si
    end

    before(:each) do
      allow(HTTP).to receive(:get).and_return(instance_double(HTTP::Response, body: StringIO.new))
    end

    # NOTE:  stanford only + location rights tested under location context
    context 'stanford only (no location qualifications)' do
      context 'webauthed user' do
        it 'allows when user webauthed and authorized' do
          allow_any_instance_of(IiifController).to receive(:current_user).and_return(user_webauth_stanford_no_loc)
          allow_any_instance_of(IiifController).to receive(:current_image).and_return(si_stanford_only)
          get "/image/iiif/#{druid}%2F#{filename}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
          expect(response).to have_http_status(200)
          expect(response.content_type).to eq('image/jpeg')
        end
        it 'blocks when user webauthed but NOT authorized' do
          allow_any_instance_of(IiifController).to receive(:current_user).and_return(user_webauth_no_stanford_no_loc)
          allow_any_instance_of(IiifController).to receive(:current_image).and_return(si_stanford_only)
          get "/image/iiif/#{druid}%2F#{filename}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
          expect(response).to have_http_status(403)
        end
      end
      it "prompts for webauth when user not webauthed" do
        allow_any_instance_of(IiifController).to receive(:current_user).and_return(user_no_loc_no_webauth)
        allow_any_instance_of(IiifController).to receive(:current_image).and_return(si_stanford_only)
        get "/image/iiif/#{druid}%2F#{filename}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
        expect(response).to redirect_to(auth_iiif_url(identifier: identifier, format: format))
      end
    end
    context 'location' do
      context 'not stanford qualified in any way' do
        it 'allows when user in location' do
          allow_any_instance_of(IiifController).to receive(:current_user).and_return(user_loc_no_webauth)
          allow_any_instance_of(IiifController).to receive(:current_image).and_return(si_loc_only)
          get "/image/iiif/#{druid}%2F#{filename}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
          expect(response).to have_http_status(200)
          expect(response.content_type).to eq('image/jpeg')
        end
        it 'blocks when user not in location' do
          allow_any_instance_of(IiifController).to receive(:current_user).and_return(user_no_loc_no_webauth)
          allow_any_instance_of(IiifController).to receive(:current_image).and_return(si_user_not_in_loc)
          get "/image/iiif/#{druid}%2F#{filename}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
          expect(response).to have_http_status(403)
        end
      end
      context 'OR stanford' do
        context 'user webauthed' do
          context 'authorized' do
            it 'allows when user in location' do
              allow_any_instance_of(IiifController).to receive(:current_user).and_return(user_webauth_stanford_loc)
              allow_any_instance_of(IiifController).to receive(:current_image).and_return(si_loc_and_stanford)
              get "/image/iiif/#{druid}%2F#{filename}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
              expect(response).to have_http_status(200)
              expect(response.content_type).to eq('image/jpeg')
            end
            it 'allows when user not in location' do
              allow_any_instance_of(IiifController).to receive(:current_user).and_return(user_webauth_stanford_no_loc)
              allow_any_instance_of(IiifController).to receive(:current_image).and_return(si_user_not_in_loc_and_stanford)
              get "/image/iiif/#{druid}%2F#{filename}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
              expect(response).to have_http_status(200)
              expect(response.content_type).to eq('image/jpeg')
            end
          end
          context 'NOT authorized' do
            it 'allows when in location' do
              allow_any_instance_of(IiifController).to receive(:current_user).and_return(user_webauth_no_stanford_loc)
              allow_any_instance_of(IiifController).to receive(:current_image).and_return(si_loc_and_stanford)
              get "/image/iiif/#{druid}%2F#{filename}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
              expect(response).to have_http_status(200)
              expect(response.content_type).to eq('image/jpeg')
            end
            it 'blocks when not in location' do
              allow_any_instance_of(IiifController).to receive(:current_user).and_return(user_webauth_no_stanford_no_loc)
              allow_any_instance_of(IiifController).to receive(:current_image).and_return(si_user_not_in_loc_and_stanford)
              get "/image/iiif/#{druid}%2F#{filename}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
              expect(response).to have_http_status(403)
            end
          end
        end
        context 'user NOT webauthed' do
          it 'allows when in location (no webauth prompt)' do
            allow_any_instance_of(IiifController).to receive(:current_user).and_return(user_loc_no_webauth)
            allow_any_instance_of(IiifController).to receive(:current_image).and_return(si_loc_and_stanford)
            get "/image/iiif/#{druid}%2F#{filename}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
            expect(response).to have_http_status(200)
            expect(response.content_type).to eq('image/jpeg')
          end
          it 'prompts for webauth when not in location' do
            allow_any_instance_of(IiifController).to receive(:current_user).and_return(user_no_loc_no_webauth)
            allow_any_instance_of(IiifController).to receive(:current_image).and_return(si_user_not_in_loc_and_stanford)
            get "/image/iiif/#{druid}%2F#{filename}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
            expect(response).to redirect_to(auth_iiif_url(identifier: identifier, format: format))
          end
        end
      end
    end
  end
end
