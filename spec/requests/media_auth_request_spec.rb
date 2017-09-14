require 'rails_helper'

RSpec.describe "Authentication for Media requests", type: :request do

  let(:user_no_loc_no_webauth) { User.new }
  let(:user_webauth_stanford_no_loc) { User.new(webauth_user: true, ldap_groups: %w(stanford:stanford)) }
  let(:druid) { 'bb582xs1304' }
  let(:identifier) { StacksIdentifier.new('bb582xs1304%2Ffile') }

  describe "#auth_check" do
    let(:format) { 'mp4' }
    let!(:sms_stanford_only) do
      sms = StacksMediaStream.new(id: identifier, format: format)
      allow(sms).to receive(:stanford_only_rights).and_return([true, ''])
      allow(sms).to receive(:restricted_by_location?).and_return(false)
      allow(sms).to receive(:location_rights).and_return([false, ''])
      allow(sms).to receive(:agent_rights).and_return([false, ''])
      allow(sms).to receive(:world_unrestricted?).and_return(false)
      allow(sms).to receive(:world_rights).and_return([false, ''])
      sms
    end
    let!(:sms_user_not_in_loc) do
      sms = StacksMediaStream.new(id: identifier, format: format)
      allow(sms).to receive(:restricted_by_location?).and_return(true)
      allow(sms).to receive(:location_rights).and_return([false, ''])
      allow(sms).to receive(:stanford_only_rights).and_return([false, ''])
      allow(sms).to receive(:agent_rights).and_return([false, ''])
      allow(sms).to receive(:world_rights).and_return([false, ''])
      sms
    end

    context 'when the user can read/stream the file' do
      it 'gets the success JSON and a token' do
        allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_stanford_no_loc)
        allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_stanford_only)
        get "/media/#{druid}/file.#{format}/auth_check.js"
        body = JSON.parse(response.body)
        expect(body['status']).to eq 'success'
        expect(body['token']).to match(/^[a-zA-Z0-9]+/)
      end
    end

    context 'when the user cannot read/stream the file' do
      context 'stanford restricted' do
        it 'indicates that the object is restricted in the json' do
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_no_loc_no_webauth)
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_stanford_only)
          get "/media/#{druid}/file.#{format}/auth_check.js"
          body = JSON.parse(response.body)
          expect(body['status']).to eq(['stanford_restricted'])
        end
      end

      context 'location restricted' do
        it 'incicates that the object is location restricted in the json' do
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_no_loc_no_webauth)
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(sms_user_not_in_loc)
          get "/media/#{druid}/file.#{format}/auth_check.js"
          body = JSON.parse(response.body)
          expect(body['status']).to eq(['location_restricted'])
        end
      end
    end
  end
end
