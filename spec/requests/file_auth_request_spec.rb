# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Authentication for File requests" do
  let(:allowed_loc) { 'ip.address1' }
  let(:user_no_loc_no_webauth) { User.new }
  let(:user_loc_no_webauth) { User.new(ip_address: allowed_loc) }
  let(:user_webauth_no_stanford_no_loc) { User.new(webauth_user: true) }
  let(:user_webauth_stanford_no_loc) { User.new(webauth_user: true, ldap_groups: %w(stanford:stanford)) }
  let(:druid) { 'nr349ct7889' }
  let(:file_name) { 'image.jp2' }
  let(:path) { storage_root.absolute_path }
  let(:storage_root) { StorageRoot.new(druid:, file_name:) }
  let(:perms) { nil }
  let(:stacks_file) { StacksFile.new(id: druid, file_name:, cocina:) }
  let(:cocina) { Cocina.new(public_json) }

  before do
    allow(Cocina).to receive(:find).and_return(cocina)
    allow(File).to receive(:world_readable?).with(path).and_return(perms)
  end

  describe "#show" do
    # NOTE:  stanford only + location rights tested under location context
    context 'stanford only (no location qualifications)' do
      let(:public_json) do
        {
          'structural' => {
            'contains' => [
              {
                'structural' => {
                  'contains' => [
                    {
                      'filename' => file_name,
                      'access' => {
                        'view' => 'stanford',
                        'download' => 'stanford'
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      end

      context 'webauthed user' do
        it 'allows when user webauthed and authorized' do
          allow_any_instance_of(FileController).to receive(:current_user).and_return(user_webauth_stanford_no_loc)
          expect_any_instance_of(FileController).to receive(:send_file).with(stacks_file.path, disposition: :inline).and_call_original
          get "/file/#{druid}/#{file_name}"
        end

        it 'blocks when user webauthed but NOT authorized' do
          allow_any_instance_of(FileController).to receive(:current_user).and_return(user_webauth_no_stanford_no_loc)
          get "/file/#{druid}/#{file_name}"
          expect(response).to have_http_status(:forbidden)
        end
      end
      it "prompts for webauth when user not webauthed" do
        allow_any_instance_of(FileController).to receive(:current_user).and_return(user_no_loc_no_webauth)
        get "/file/#{druid}/#{file_name}"
        expect(response).to redirect_to(auth_file_url(id: druid, file_name:))
      end
    end
    context 'location' do
      context 'not stanford qualified in any way' do
        let(:public_json) do
          {
            'structural' => {
              'contains' => [
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => file_name,
                        'access' => {
                          'view' => 'location-based',
                          'download' => 'location-based',
                          'location' => 'location1'
                        }
                      }
                    ]
                  }
                }
              ]
            }
          }
        end

        it 'allows when user in location' do
          allow_any_instance_of(FileController).to receive(:current_user).and_return(user_loc_no_webauth)
          expect_any_instance_of(FileController).to receive(:send_file).with(stacks_file.path, disposition: :inline).and_call_original
          get "/file/#{druid}/#{file_name}"
        end

        it 'blocks when user not in location' do
          allow_any_instance_of(FileController).to receive(:current_user).and_return(user_no_loc_no_webauth)
          get "/file/#{druid}/#{file_name}"
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
