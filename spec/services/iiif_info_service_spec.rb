# frozen_string_literal: true

require 'rails_helper'

RSpec.describe IiifInfoService do
  describe '#info' do
    subject(:image_info) do
      described_class.info(image, downloadable_anonymously, context)
    end

    let(:context) do
      double('routing context',
             iiif_auth_api_url: 'http://foo/auth/api',
             iiif_token_api_url: 'http://foo/token/api',
             logout_url: 'http://foo/logout',
             cdl_checkout_iiif_auth_api_url: 'http://cdl/out',
             cdl_checkin_iiif_auth_api_url: 'http://cdl/in',
             cdl_info_iiif_auth_api_url: 'http://cdl/info',
             cdl_iiif_token_api_url: 'http://cdl/token',
             cdl_renew_iiif_auth_api_url: 'http://cdl/renew')
    end
    let(:downloadable_anonymously) { true }
    let(:image) do
      StacksImage.new(id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001')
    end
    let(:source_info) { {} }

    before do
      allow(image).to receive_messages(info: source_info,
                                       maybe_downloadable?: true,
                                       restricted_by_location?: false)
    end

    # This is kind of a round-about way to test this,
    # but the actual logic that we're depending on
    # here is buried in the djatoka gem
    context 'when the image is downloadable' do
      let(:source_info) do
        { tile_height: 1024,
          tile_width: 1024,
          '@context' => [],
          'tiles' => [{ 'width' => 1024, 'height' => 1024 }] }
      end

      it 'the tile height/width is 1024' do
        expect(image_info[:tile_height]).to eq 1024
        expect(image_info[:tile_width]).to eq 1024
      end

      it 'includes a recommended tile size' do
        expect(image_info['tiles'].first).to include 'width' => 1024, 'height' => 1024
      end

      it 'omits the authentication service' do
        expect(image_info['service']).not_to be_present
      end

      it 'has the profile' do
        expect(image_info['profile']).to eq ['http://iiif.io/api/image/2/level2.json']
      end
    end

    context 'when the sizes are too large to actually deliver' do
      let(:source_info) do
        {
          'sizes' => [
            { 'width' => 512, 'height' => 512 },
            { 'width' => 512_000, 'height' => 512_000 }
          ]
        }
      end

      it 'trims out sizes that are over the maximum servable' do
        expect(image_info['sizes']).to eq [{ 'width' => 512, 'height' => 512 }]
      end
    end

    context 'when the tile is exaggerated in dimensions' do
      let(:source_info) do
        { tile_height: 48_915,
          tile_width: 512,
          '@context' => [],
          'tiles' => [{ 'width' => 512, 'height' => 48_915 }] }
      end

      it 'reduces the tile size' do
        expect(image_info['tiles'].first).to include 'width' => 512, 'height' => 512
      end
    end

    context 'when the tile is not exaggerated in dimensions' do
      let(:source_info) do
        { tile_height: 20_480,
          tile_width: 512,
          '@context' => [],
          'tiles' => [{ 'width' => 512, 'height' => 20_480 }] }
      end

      it 'retains the tile size' do
        expect(image_info['tiles'].first).to include 'width' => 512, 'height' => 20_480
      end
    end

    context 'when the image is not downloadable' do
      let(:image) do
        RestrictedImage.new(id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001')
      end
      let(:downloadable_anonymously) { false }
      let(:source_info) { { tile_height: 256, tile_width: 256 } }
      let(:auth_service) { image_info['service'] }

      before do
        allow(image).to receive_messages(stanford_restricted?: true)
      end

      it 'the tile height/width is 256' do
        expect(image_info[:tile_height]).to eq 256
        expect(image_info[:tile_width]).to eq 256
      end

      it 'advertises an authentication service' do
        expect(auth_service).to be_present
        expect(auth_service['@context']).to eq 'http://iiif.io/api/auth/1/context.json'
        expect(auth_service['profile']).to eq 'http://iiif.io/api/auth/1/login'
        expect(auth_service['@id']).to eq 'http://foo/auth/api'

        expect(auth_service['service'].first['profile']).to eq 'http://iiif.io/api/auth/1/token'
        expect(auth_service['service'].first['@id']).to eq 'http://foo/token/api'
        expect(auth_service['label']).to eq 'Stanford users: log in to access all available features.'
        expect(auth_service['confirmLabel']).to eq 'Log in'
        expect(auth_service['failureHeader']).to eq 'Unable to authenticate'
        expect(auth_service['failureDescription']).to eq 'The authentication service cannot be reached.'
        expect(auth_service['header']).to eq 'Stanford-affiliated? Log in to view'
        expect(auth_service['description']).to eq 'Stanford users can click Log ' \
                                                  'in below to access all features.'
      end

      it 'advertises a logout service' do
        logout_service = auth_service['service'].find { |x| x['profile'] == 'http://iiif.io/api/auth/1/logout' }
        expect(logout_service['profile']).to eq 'http://iiif.io/api/auth/1/logout'
        expect(logout_service['@id']).to eq 'http://foo/logout'
        expect(logout_service['label']).to eq 'Logout'
      end
    end

    context 'when the image is location-restricted' do
      let(:image) do
        RestrictedImage.new(id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001')
      end
      let(:downloadable_anonymously) { false }

      let(:location_service) { image_info['service'] }
      let(:public_json) do
        {
          'structural' => {
            'contains' => [
              {
                'structural' => {
                  'contains' => [
                    {
                      'filename' => 'nr349ct7889_00_0001',
                      'access' => {
                        'view' => 'location-based',
                        'download' => 'location-based',
                        'location' => 'spec'
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
        allow(Purl).to receive(:public_json).and_return(public_json)

        stub_rights_xml(world_readable_rights_xml)
        allow(image).to receive(:restricted_by_location?).and_return(true)
      end

      it 'advertises an authentication service' do
        location_restriction_msg = 'Restricted content cannot be accessed from your location'
        expect(location_service).to be_present
        expect(location_service['@context']).to eq 'http://iiif.io/api/auth/1/context.json'
        expect(location_service['profile']).to eq 'http://iiif.io/api/auth/1/external'
        expect(location_service['label']).to eq 'External Authentication Required'
        expect(location_service['failureHeader']).to eq 'Restricted Material'
        expect(location_service['failureDescription']).to eq location_restriction_msg
        expect(location_service['service'].first['profile']).to eq 'http://iiif.io/api/auth/1/token'
        expect(location_service['service'].first['@id']).to eq 'http://foo/token/api'
      end
    end

    context 'when the item has location and stanford-only rights' do
      let(:image) do
        RestrictedImage.new(id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001')
      end
      let(:downloadable_anonymously) { false }

      let(:public_json) do
        {
          'structural' => {
            'contains' => [
              {
                'structural' => {
                  'contains' => [
                    {
                      'filename' => 'nr349ct7889_00_0001',
                      'access' => {
                        'view' => 'stanford',
                        'download' => 'stanford'
                      },
                      'hasMimeType' => 'text/csv'
                    }
                  ]
                }
              }
            ]
          }
        }
      end

      before do
        allow(Purl).to receive(:public_json).and_return(public_json)
        stub_rights_xml(world_readable_rights_xml)
        allow(image).to receive_messages(stanford_restricted?: true, restricted_by_location?: true)
      end

      it 'advertises support for both login and external authentication' do
        expect(image_info['service']).to be_present
        expect(image_info['service'].length).to eq 2
        expect(image_info['service'].pluck('profile')).to contain_exactly('http://iiif.io/api/auth/1/login', 'http://iiif.io/api/auth/1/external')
      end
    end
  end
end
