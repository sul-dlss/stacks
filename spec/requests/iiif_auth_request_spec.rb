# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Authentication for IIIF requests" do

  let(:allowed_loc) { 'ip.address1' }
  let(:user_no_loc_no_webauth) { User.new }
  let(:user_loc_no_webauth) { User.new(ip_address: allowed_loc) }
  let(:user_webauth_no_stanford_no_loc) { User.new(webauth_user: true) }
  let(:user_webauth_stanford_no_loc) { User.new(webauth_user: true, ldap_groups: %w(stanford:stanford)) }
  let(:user_webauth_stanford_loc) { User.new(webauth_user: true, ldap_groups: %w(stanford:stanford), ip_address: allowed_loc) }
  let(:user_webauth_no_stanford_loc) { User.new(webauth_user: true, ip_address: allowed_loc) }
  let(:region) { '0,640,2552,2552' }
  let(:size) { '100,100' }
  let(:rotation) { '0' }
  let(:quality) { 'default' }
  let(:format) { 'jpg' }
  let(:identifier) { "#{druid}%2F#{file_name}" }
  let(:params_hash) { { id: druid, file_name:, transformation: } }
  let(:transformation) { IIIF::Image::Transformation.new region:, size:, rotation:, quality:, format: }
  let(:druid) { 'nr349ct7889' }
  let(:file_name) { 'image.jp2' }
  let(:path) { storage_root.absolute_path }
  let(:storage_root) { StorageRoot.new(druid:, file_name:) }
  let(:perms) { nil }
  let(:current_image) { StacksImage.new(params_hash) }
  let(:http_client) { instance_double(HTTP::Client) }

  before(:each) do
    allow(File).to receive(:world_readable?).with(path).and_return(perms)
  end

  describe "#show" do
    before do
      allow_any_instance_of(Projection).to receive(:valid?).and_return(true)
      allow(HTTP).to receive(:use).and_return(http_client)
      allow(http_client).to receive(:get).and_return(instance_double(HTTP::Response, status: 200, body: StringIO.new))
      allow_any_instance_of(IiifController).to receive(:current_user).and_return(current_user)
      allow_any_instance_of(IiifController).to receive(:current_image).and_return(current_image)
      allow(Purl).to receive(:public_json).and_return(public_json)
    end

    context 'with a public item' do
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
                        'view' => 'world',
                        'download' => 'world'
                      }
                    }
                  ]
                }
              }
            ]
          }
        }
      end

      before do
        stub_rights_xml(world_readable_rights_xml)
      end

      context 'with an unauthenticated user' do
        let(:current_user) { user_no_loc_no_webauth }

        it 'works' do
          get "/image/iiif/#{identifier}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq('image/jpeg')
        end
      end
    end

    context 'with a stanford only item' do
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

      before do
        stub_rights_xml(stanford_restricted_rights_xml)
      end

      context 'with a authorized webauthed user' do
        let(:current_user) { user_webauth_stanford_no_loc }

        it 'works' do
          get "/image/iiif/#{identifier}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq('image/jpeg')
        end
      end

      context 'with a unauthorized webauthed user' do
        let(:current_user) { user_webauth_no_stanford_no_loc }

        it 'blocks' do
          get "/image/iiif/#{identifier}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
          expect(response).to have_http_status(:forbidden)
        end
      end

      context 'with an unauthenticated user' do
        let(:current_user) { user_no_loc_no_webauth }

        it 'redirects to the authentication endpoint' do
          get "/image/iiif/#{identifier}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
          expect(response).to redirect_to(auth_iiif_url(id: druid, file_name:, format:))
        end
      end
    end

    context 'with a location-restricted item' do
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

      before do
        stub_rights_xml(location_rights_xml)
      end

      context 'with a user in the location' do
        let(:current_user) { user_loc_no_webauth }

        it 'works' do
          get "/image/iiif/#{identifier}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq('image/jpeg')
        end
      end

      context 'with a user outside the location' do
        let(:current_user) { user_no_loc_no_webauth }

        it 'blocks' do
          get "/image/iiif/#{identifier}/#{region}/#{size}/#{rotation}/#{quality}.#{format}"
          expect(response).to have_http_status(:forbidden)
        end
      end
    end
  end
end
