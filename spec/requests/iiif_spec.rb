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

  before do
    allow(Cocina).to receive(:find).and_return(Cocina.new(public_json))
    allow(IiifMetadataService).to receive(:new).and_return(metadata_service)
  end

  context 'with versioned file layout' do
    let(:public_json) do
      Factories.cocina_with_file
    end

    context 'with a bare identifier' do
      it 'redirects base uri requests to the info.json document' do
        get '/image/iiif/bb000cr7262/abc'

        expect(response).to redirect_to('/image/iiif/bb000cr7262/abc/info.json')
        expect(response).to have_http_status :see_other
      end
    end

    describe 'metadata requests' do
      it 'handles JSON requests' do
        get '/image/iiif/bb000cr7262%2Fimage/info.json', headers: { HTTP_ACCEPT: 'application/json' }

        expect(response.media_type).to eq 'application/json'
        json = response.parsed_body
        expect(json['tiles']).to eq [{ 'width' => 256, 'height' => 256, 'scaleFactors' => [1, 2, 4, 8, 16] }]
        expect(response.headers['Link']).to eq '<http://iiif.io/api/image/2/level2.json>;rel="profile"'
      end

      it 'handles JSON-LD requests' do
        get '/image/iiif/bb000cr7262%2Fimage/info.json', headers: { HTTP_ACCEPT: 'application/ld+json' }

        expect(response.media_type).to eq 'application/ld+json'
        json = JSON.parse(response.body) # rubocop:disable Rails/ResponseParsedBody
        expect(json['tiles']).to eq [{ 'width' => 256, 'height' => 256, 'scaleFactors' => [1, 2, 4, 8, 16] }]
      end

      context 'for location-restricted documents' do
        context 'outside of the location' do
          context 'when the file is not a thumbnail' do
            let(:public_json) do
              Factories.cocina_with_file(file_access: {
                                           'view' => 'location-based',
                                           'download' => 'location-based',
                                           'location' => 'location1'
                                         },
                                         mime_type: 'image/jpeg')
            end

            it 'uses the unauthorized status code for the response' do
              get '/image/iiif/bb000cr7262%2Fimage/info.json'
              expect(response).to have_http_status :unauthorized
            end
          end

          context 'when the files is a thumbnail' do
            let(:public_json) do
              Factories.cocina_with_file(file_access: {
                                           'view' => 'location-based',
                                           'download' => 'location-based',
                                           'location' => 'location1'
                                         })
            end

            it 'redirects requests to the degraded info.json' do
              get '/image/iiif/bb000cr7262%2Fimage/info.json'
              expect(response).to have_http_status :redirect
              expect(response).to redirect_to('/image/iiif/degraded/bb000cr7262/image/info.json')
              expect(response.headers['Cache-Control']).to match(/max-age=0/)
            end
          end
        end

        context 'at the location' do
          let(:user) { User.new(ip_address: 'ip.address1') }
          let(:public_json) do
            Factories.cocina_with_file(file_access: { 'view' => 'location-based', 'download' => 'location-based',
                                                      'location' => 'location1' })
          end

          before do
            allow_any_instance_of(IiifController).to receive(:current_user).and_return(user)
          end

          it 'uses the ok status code for the response' do
            get '/image/iiif/bb000cr7262%2Fimage/info.json'
            expect(response).to have_http_status :ok
          end
        end
      end

      context 'for stanford-restricted documents' do
        let(:public_json) do
          Factories.cocina_with_file(file_access: { 'view' => 'stanford', 'download' => 'stanford' })
        end

        it 'redirects requests to the degraded info.json' do
          get '/image/iiif/bb000cr7262/image/info.json'
          expect(response).to have_http_status :redirect
          expect(response).to redirect_to('/image/iiif/degraded/bb000cr7262/image/info.json')
          expect(response.headers['Cache-Control']).to match(/max-age=0/)
        end

        context 'when connecting to the degraded url' do
          it 'serves a degraded info.json description for the original file' do
            get '/image/iiif/degraded/bb000cr7262/image/info.json'

            expect(response).to have_http_status :ok
            expect(controller.send(:current_image).stacks_file.id).to eq 'bb000cr7262'
          end
        end
      end

      context 'where no one can download' do
        let(:public_json) do
          Factories.cocina_with_file(file_access: { 'view' => 'world', 'download' => 'none' })
        end

        it 'serves up regular info.json (no degraded)' do
          get '/image/iiif/bb000cr7262%2Fimage/info.json'
          expect(response).to have_http_status :ok
        end

        it 'replaces the sizes element to reflect the only downloadable (thumbnail) size' do
          get '/image/iiif/bb000cr7262%2Fimage/info.json'
          json = response.parsed_body

          expect(json['sizes']).to eq [{ 'width' => 266, 'height' => 400 }]
        end
      end

      context 'where stanford only no download rights' do
        let(:public_json) do
          Factories.cocina_with_file(file_access: { 'view' => 'stanford', 'download' => 'none' })
        end

        it 'redirects to degraded version' do
          get '/image/iiif/bb000cr7262/image/info.json'
          expect(response).to have_http_status :redirect
          expect(response).to redirect_to('/image/iiif/degraded/bb000cr7262/image/info.json')
        end
      end
    end

    describe 'image requests for world readable items' do
      let(:image_path_component) { "bb%2F000%2Fcr%2F7262%2Fbb000cr7262%2Fcontent%2F8ff299eda08d7c506273840d52a03bf3" }

      context 'when the request is valid' do
        before do
          stub_request(:get, "http://imageserver-prod.stanford.edu/iiif/2/#{image_path_component}/0,640,2552,2552/100,100/0/default.jpg")
            .to_return(status: 200, body: "")
        end

        it 'loads the image' do
          get "/image/iiif/bb000cr7262%2Fimage/0,640,2552,2552/100,100/0/default.jpg"

          expect(response.media_type).to eq 'image/jpeg'
          expect(response).to have_http_status :ok
        end
      end

      context 'when additional params are provided' do
        before do
          stub_request(:get, "http://imageserver-prod.stanford.edu/iiif/2/#{image_path_component}/0,640,2552,2552/100,100/0/default.jpg")
            .to_return(status: 200, body: "")
        end

        it 'is ignored when instantiating StacksImage' do
          get "/image/iiif/bb000cr7262%2Fimage/0,640,2552,2552/100,100/0/default.jpg?ignored=ignored&host=host"

          expect(response).to have_http_status :ok
        end
      end

      context 'when image is missing' do
        before do
          stub_request(:get, "http://imageserver-prod.stanford.edu/iiif/2/#{image_path_component}/0,640,2552,2552/100,100/0/default.jpg")
            .to_return(status: 404, body: "")
        end

        it 'returns 404 Not Found' do
          get "/image/iiif/bb000cr7262%2Fimage/0,640,2552,2552/100,100/0/default.jpg?ignored=ignored&host=host"
          expect(response).to have_http_status :not_found
        end
      end

      context 'when the object has no filesets (e.g. a collection)' do
        let(:public_json) do
          { 'structural' => {} }
        end

        it 'returns 404 Not Found' do
          get "/image/iiif/bb000cr7262%2Fimage/0,640,2552,2552/100,100/0/default.jpg"
          expect(response).to have_http_status :not_found
        end
      end

      context 'with the download flag set' do
        before do
          stub_request(:get, "http://imageserver-prod.stanford.edu/iiif/2/#{image_path_component}/0,640,2552,2552/100,100/0/default.jpg")
            .to_return(status: 200, body: "")
        end

        it 'sets the content-disposition header' do
          get "/image/iiif/bb000cr7262%2Fimage/0,640,2552,2552/100,100/0/default.jpg?download=true"

          expect(response.headers['Content-Disposition']).to start_with 'attachment'
          expect(response.headers['Content-Disposition']).to include 'filename="image.jpg"'
        end
      end

      context 'with a pct region' do
        before do
          stub_request(:get, "http://imageserver-prod.stanford.edu/iiif/2/#{image_path_component}/pct:3.0,3.0,77.0,77.0/full/0/default.jpg")
            .to_return(status: 200, body: "")
        end

        it 'loads the image' do
          get '/image/iiif/bb000cr7262%2Fimage/pct:3,3,77,77/full/0/default.jpg'

          expect(response.media_type).to eq 'image/jpeg'
          expect(response).to have_http_status :ok
        end
      end
    end
  end
end
