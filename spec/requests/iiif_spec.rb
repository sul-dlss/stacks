# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'IIIF API' do
  let(:metadata) do
    { 'height' => 2099,
      'width' => 1702,
      'tiles' => [{ 'width' => 256, "height" => 256, "scaleFactors" => [1, 2, 4, 8, 16] }] }
  end
  let(:metadata_service) do
    instance_double(IiifMetadataService, fetch: metadata,
                                         image_width: 1702,
                                         image_height: 2552)
  end
  let(:stacks_image) do
    StacksImage.new(id: 'nr349ct7889', file_name: 'nr349ct7889_00_0001.jp2')
  end
  let(:file_source) do
    instance_double(StacksFile, readable?: true,
                                etag: 'etag',
                                mtime: Time.zone.now)
  end

  let(:public_json) do
    {
      'structural' => {
        'contains' => [
          {
            'structural' => {
              'contains' => [
                {
                  'filename' => 'nr349ct7889_00_0001.jp2',
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
    allow(Purl).to receive(:public_json).and_return(public_json)

    # stubbing Rails.cache.fetch is required because you can't dump a singleton (double)
    # which is what happens when writing to the cache.
    allow(Rails.cache).to receive(:fetch).and_yield
    allow(StacksImage).to receive(:new).and_return(stacks_image)
    allow(stacks_image).to receive(:file_source).and_return(file_source)
    allow(IiifMetadataService).to receive(:new).and_return(metadata_service)
  end

  context 'with a bare identifier' do
    it 'redirects base uri requests to the info.json document' do
      get '/image/iiif/nr349ct7889/abc'

      expect(response).to redirect_to('/image/iiif/nr349ct7889/abc/info.json')
      expect(response).to have_http_status :see_other
    end
  end

  describe 'metadata requests' do
    it 'handles JSON requests' do
      get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json', headers: { HTTP_ACCEPT: 'application/json' }

      expect(response.media_type).to eq 'application/json'
      json = response.parsed_body
      expect(json['tiles']).to eq [{ 'width' => 256, 'height' => 256, 'scaleFactors' => [1, 2, 4, 8, 16] }]
      expect(response.headers['Link']).to eq '<http://iiif.io/api/image/2/level2.json>;rel="profile"'
    end

    it 'handles JSON-LD requests' do
      get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json', headers: { HTTP_ACCEPT: 'application/ld+json' }

      expect(response.media_type).to eq 'application/ld+json'
      json = JSON.parse(response.body) # rubocop:disable Rails/ResponseParsedBody
      expect(json['tiles']).to eq [{ 'width' => 256, 'height' => 256, 'scaleFactors' => [1, 2, 4, 8, 16] }]
    end

    context 'for location-restricted documents' do
      let(:public_json) do
        {
          'structural' => {
            'contains' => [
              {
                'structural' => {
                  'contains' => [
                    {
                      'filename' => 'nr349ct7889_00_0001.jp2',
                      'access' => {
                        'view' => 'location-based',
                        'download' => 'location_based',
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

      context 'outside of the location' do
        it 'uses the unauthorized status code for the response' do
          get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json'
          expect(response).to have_http_status :unauthorized
        end

        context 'for a thumbnail' do
          before do
            stub_rights_xml(location_thumbnail_rights_xml)
          end
          let(:public_json) do
            {
              'structural' => {
                'contains' => [
                  {
                    'structural' => {
                      'contains' => [
                        {
                          'filename' => 'nr349ct7889_00_0001.jp2',
                          'access' => {
                            'view' => 'location-based',
                            'download' => 'location_based',
                            'location' => 'location1'
                          },
                          'hasMimeType' => 'image/jp2'
                        }
                      ]
                    }
                  }
                ]
              }
            }
          end

          it 'redirects requests to the degraded info.json' do
            get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json'
            expect(response).to have_http_status :redirect
            expect(response).to redirect_to('/image/iiif/degraded/nr349ct7889/nr349ct7889_00_0001/info.json')
            expect(response.headers['Cache-Control']).to match(/max-age=0/)
          end
        end
      end

      context 'at the location' do
        let(:user) { User.new(ip_address: 'ip.address1') }
        before do
          allow_any_instance_of(IiifController).to receive(:current_user).and_return(user)
        end
        it 'uses the ok status code for the response' do
          get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json'
          expect(response).to have_http_status :ok
        end
      end
    end

    context 'for stanford-restricted documents' do
      let(:public_json) do
        {
          'structural' => {
            'contains' => [
              {
                'structural' => {
                  'contains' => [
                    {
                      'filename' => 'nr349ct7889_00_0001.jp2',
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

      it 'redirects requests to the degraded info.json' do
        get '/image/iiif/nr349ct7889/nr349ct7889_00_0001/info.json'
        expect(response).to have_http_status :redirect
        expect(response).to redirect_to('/image/iiif/degraded/nr349ct7889/nr349ct7889_00_0001/info.json')
        expect(response.headers['Cache-Control']).to match(/max-age=0/)
      end

      context 'when connecting to the degraded url' do
        it 'serves a degraded info.json description for the original file' do
          get '/image/iiif/degraded/nr349ct7889/nr349ct7889_00_0001/info.json'

          expect(response).to have_http_status :ok
          expect(controller.send(:current_image).id).to eq 'nr349ct7889'
        end
      end
    end

    context 'rights xml where no one can download' do
      let(:public_json) do
        {
          'structural' => {
            'contains' => [
              {
                'structural' => {
                  'contains' => [
                    {
                      'filename' => 'nr349ct7889_00_0001.jp2',
                      'access' => {
                        'view' => 'world',
                        'download' => 'none'
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
        stub_rights_xml(world_no_download_xml)
      end
      it 'serves up regular info.json (no degraded)' do
        get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json'
        expect(response).to have_http_status :ok
      end

      it 'replaces the sizes element to reflect the only downloadable (thumbnail) size' do
        get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/info.json'
        json = response.parsed_body

        expect(json['sizes']).to eq [{ 'width' => 266, 'height' => 400 }]
      end
    end

    context 'rights xml where stanford only no download' do
      let(:public_json) do
        {
          'structural' => {
            'contains' => [
              {
                'structural' => {
                  'contains' => [
                    {
                      'filename' => 'nr349ct7889_00_0001.jp2',
                      'access' => {
                        'view' => 'stanford',
                        'download' => 'none'
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
        stub_rights_xml(stanford_only_no_download_xml)
      end
      it 'redirects to degraded version' do
        get '/image/iiif/nr349ct7889/nr349ct7889_00_0001/info.json'
        expect(response).to have_http_status :redirect
        expect(response).to redirect_to('/image/iiif/degraded/nr349ct7889/nr349ct7889_00_0001/info.json')
      end
    end
  end

  describe 'image requests for world readable items' do
    let(:ability) { instance_double(Ability, can?: false) }

    before do
      # for the cache headers
      allow_any_instance_of(IiifController).to receive(:anonymous_ability).and_return ability
      # for authorize! in #show
      allow_any_instance_of(IiifController).to receive(:authorize!).with(:read, Projection).and_return(true)
      # for current_image
      allow_any_instance_of(IiifController).to receive(:can?).with(:download, StacksImage).and_return(true)
    end

    context 'when the request is valid' do
      before do
        stub_request(:get, "http://imageserver-prod.stanford.edu/iiif/2/nr%2F349%2Fct%2F7889%2Fnr349ct7889_00_0001.jp2/0,640,2552,2552/100,100/0/default.jpg")
          .to_return(status: 200, body: "")
      end

      it 'loads the image' do
        get "/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,640,2552,2552/100,100/0/default.jpg"

        expect(StacksImage).to have_received(:new).with(
          id: "nr349ct7889", file_name: 'nr349ct7889_00_0001.jp2',
          canonical_url: "http://www.example.com/image/iiif/nr349ct7889/nr349ct7889_00_0001"
        )
        expect(response.media_type).to eq 'image/jpeg'
        expect(response).to have_http_status :ok
      end
    end

    context 'when additional params are provided' do
      before do
        stub_request(:get, "http://imageserver-prod.stanford.edu/iiif/2/nr%2F349%2Fct%2F7889%2Fnr349ct7889_00_0001.jp2/0,640,2552,2552/100,100/0/default.jpg")
          .to_return(status: 200, body: "")
      end

      it 'is ignored when instantiating StacksImage' do
        get "/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,640,2552,2552/100,100/0/default.jpg?ignored=ignored&host=host"

        expect(response).to have_http_status :ok
      end
    end

    context 'when image is missing' do
      before do
        stub_request(:get, "http://imageserver-prod.stanford.edu/iiif/2/nr%2F349%2Fct%2F7889%2Fnr349ct7889_00_0001.jp2/0,640,2552,2552/100,100/0/default.jpg")
          .to_return(status: 404, body: "")
      end

      it 'returns 404 Not Found' do
        get "/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,640,2552,2552/100,100/0/default.jpg?ignored=ignored&host=host"
        expect(response).to have_http_status :not_found
      end
    end

    context 'with the download flag set' do
      before do
        stub_request(:get, "http://imageserver-prod.stanford.edu/iiif/2/nr%2F349%2Fct%2F7889%2Fnr349ct7889_00_0001.jp2/0,640,2552,2552/100,100/0/default.jpg")
          .to_return(status: 200, body: "")
      end

      it 'sets the content-disposition header' do
        get "/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/0,640,2552,2552/100,100/0/default.jpg?download=true"

        expect(response.headers['Content-Disposition']).to start_with 'attachment'
        expect(response.headers['Content-Disposition']).to include 'filename="nr349ct7889_00_0001.jpg"'
      end
    end

    context 'with a pct region' do
      before do
        stub_request(:get, "http://imageserver-prod.stanford.edu/iiif/2/nr%2F349%2Fct%2F7889%2Fnr349ct7889_00_0001.jp2/pct:3.0,3.0,77.0,77.0/full/0/default.jpg")
          .to_return(status: 200, body: "")
      end

      it 'loads the image' do
        get '/image/iiif/nr349ct7889%2Fnr349ct7889_00_0001/pct:3,3,77,77/full/0/default.jpg'

        expect(response.media_type).to eq 'image/jpeg'
        expect(response).to have_http_status :ok
      end
    end
  end
end
