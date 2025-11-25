# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'IIIF auth v2 probe service' do
  let(:id) { 'bb000cr7262' }
  let(:file_name) { 'image.jp2' }
  let(:stacks_uri) { "https://stacks-uat.stanford.edu/file/druid:#{id}/#{URI.encode_uri_component(file_name)}" }
  let(:stacks_uri_param) { URI.encode_uri_component(stacks_uri) }
  let(:public_json) { Factories.cocina }

  # NOTE: For any unauthorized responses, the status from the service is OK...the access status of the resource is in the response body

  before do
    allow(Cocina).to receive(:find).and_return(Cocina.new(public_json))
    allow(File).to receive(:world_readable?).and_return('420')
    allow(StacksFile).to receive(:new).and_call_original
  end

  describe 'pre-flight request' do
    before do
      options "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    it 'sets the headers' do
      expect(response).to have_http_status :no_content
      expect(response.headers['Access-Control-Allow-Origin']).to eq '*'
    end
  end

  context 'when the URI is not properly encoded' do
    let(:file_name) { 'this has spaces.pdf' }
    let(:stacks_uri) { "https://stacks-uat.stanford.edu/file/druid:#{id}/#{file_name}" }

    before do
      get "/iiif/auth/v2/probe?id=#{stacks_uri}"
    end

    it 'returns a success response' do
      expect(response).to have_http_status :bad_request
    end
  end

  context "when the druid in the passed in uri isn't formatted correctly" do
    let(:id) { '111' }

    before do
      allow(Cocina).to receive(:find).and_raise(Purl::Exception)
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    it 'returns a success response' do
      expect(response).to have_http_status :ok
      expect(response.parsed_body).to eq("@context" => "http://iiif.io/api/auth/2/context.json",
                                         "heading" => { "en" => ["Unable to find 111"] },
                                         "status" => 404,
                                         "type" => "AuthProbeResult2")
    end
  end

  context "when the passed in uri isn't a stacks resource" do
    let(:stacks_uri) { "https://example.com" }

    before do
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    it 'is a bad_request' do
      expect(response).to have_http_status :bad_request
    end
  end

  context 'when versioned, the user has access to the resource because it is world accessible' do
    let(:id) { 'bb000cr7262' }
    let(:stacks_uri) { "https://stacks-uat.stanford.edu/v2/file/druid:#{id}/version/1/#{URI.encode_uri_component(file_name)}" }
    let(:public_json) do
      Factories.cocina_with_file(file_name:)
    end

    before do
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    context 'when druid has a prefix' do
      it 'returns a success response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 200
                                                })
      end
    end

    context 'without a druid prefix' do
      let(:stacks_uri) { "https://stacks-uat.stanford.edu/v2/file/#{id}/version/1/#{URI.encode_uri_component(file_name)}" }

      it 'returns a success response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 200
                                                })
      end
    end

    context 'when filename with spaces' do
      let(:file_name) { 'SC0193 1982-013 b06 f01 1981-09-29.pdf' }

      it 'returns a success response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 200
                                                })
      end
    end
  end

  context 'when the user has access to the resource because it is world accessible' do
    let(:public_json) do
      Factories.cocina_with_file(file_name:)
    end

    before do
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    context 'when druid has a prefix' do
      it 'returns a success response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 200
                                                })
      end
    end

    context 'without a druid prefix' do
      let(:stacks_uri) { "https://stacks-uat.stanford.edu/file/#{id}/#{URI.encode_uri_component(file_name)}" }

      it 'returns a success response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 200
                                                })
      end
    end

    context 'when filename with spaces' do
      let(:file_name) { 'SC0193 1982-013 b06 f01 1981-09-29.pdf' }

      it 'returns a success response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 200
                                                })
      end
    end
  end

  context 'when the user has access to the resource and it is streamable' do
    let(:file_name) { 'SC0193_1982-013_b06_f01_1981-09-29.mp4' }
    let(:public_json) do
      Factories.cocina_with_file(file_name:)
    end
    let(:stacks_uri) { "https://stacks-uat.stanford.edu/file/#{id}/#{URI.encode_uri_component(file_name)}" }

    before do
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    it 'returns a success response' do
      expect(response).to have_http_status :ok

      expect(response.parsed_body).to include({
                                                "@context" => "http://iiif.io/api/auth/2/context.json",
                                                "type" => "AuthProbeResult2",
                                                "status" => 302
                                              })
      location = response.parsed_body.dig('location', 'id')
      expect(location).to start_with 'https://sul-mediaserver.stanford.edu/stacks-with-token/_definst_/weka/bb/000/cr/7262/bb000cr7262/content/mp4:8ff299eda08d7c506273840d52a03bf3/playlist.m3u8?wowzatokenendtime='
      expect(location).to end_with('=') # Token is md5 encoded
    end
  end

  context 'when versioned, the user has access to the resource and it is streamable' do
    let(:file_name) { 'SC0193_1982-013_b06_f01_1981-09-29.mp4' }
    let(:id) { 'bb000cr7262' }

    let(:public_json) do
      Factories.cocina_with_file(file_name:)
    end
    let(:stacks_uri) { "https://stacks-uat.stanford.edu/v2/file/#{id}/version/1/#{URI.encode_uri_component(file_name)}" }

    before do
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    it 'returns a success response' do
      expect(response).to have_http_status :ok

      expect(response.parsed_body).to include({
                                                "@context" => "http://iiif.io/api/auth/2/context.json",
                                                "type" => "AuthProbeResult2",
                                                "status" => 302
                                              })
      location = response.parsed_body.dig('location', 'id')
      expect(location).to start_with 'https://sul-mediaserver.stanford.edu/stacks-with-token/_definst_/weka/bb/000/cr/7262/bb000cr7262/content/mp4:8ff299eda08d7c506273840d52a03bf3/playlist.m3u8?wowzatokenendtime='
      expect(location).to end_with('=') # Token is md5 encoded
    end
  end

  context 'when the requested file does not exist' do
    before do
      # allow_any_instance_of(StacksFile).to receive(:readable?).and_return(nil)
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    let(:stacks_uri) { "https://stacks-uat.stanford.edu/file/druid:#{id}/#{URI.encode_uri_component('unknown_file.png')}" }

    let(:public_json) do
      Factories.cocina_with_file(file_name:)
    end

    it 'returns a 404 response' do
      expect(response).to have_http_status :ok
      expect(response.parsed_body).to include({
                                                "@context" => "http://iiif.io/api/auth/2/context.json",
                                                "type" => "AuthProbeResult2",
                                                "status" => 404
                                              })
    end
  end

  context 'when a Stanford only resource' do
    let(:public_json) do
      Factories.cocina_with_file(file_access: { 'view' => 'stanford', 'download' => 'stanford' }, file_name:)
    end
    let(:token) { nil }

    before do
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}", headers: { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
    end

    context 'when the user does not have a token' do
      it 'returns a unauthorized response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "heading" => { "en" => [I18n.t('probe_service.stanford')] },
                                                  "icon" => I18n.t('probe_service.stanford_icon'),
                                                  "status" => 401
                                                })
      end
    end

    context 'when the user has a bearer token with the ldap group' do
      let(:user_webauth_stanford_no_loc) { User.new(webauth_user: true, ldap_groups: %w[stanford:stanford]) }
      let(:token) { user_webauth_stanford_no_loc.token }

      it 'returns a success response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 200
                                                })
      end
    end

    context 'when the user does not provide a token' do
      before do
        get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
      end

      it 'returns a not authorized response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 401,
                                                  "heading" => { "en" => ["Stanford users: log in to access all available features."] },
                                                  "note" => { "en" => ["Access restricted"] }
                                                })
      end

      context 'when object has a hierarchically nested filename' do
        let(:file_name) { 'folder/SC0193_1982-013_b06_f01_1981-09-29.pdf' }

        before do
          get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
        end

        it 'returns a not authorized response' do
          expect(response).to have_http_status :ok
          expect(response.parsed_body).to include({
                                                    "@context" => "http://iiif.io/api/auth/2/context.json",
                                                    "type" => "AuthProbeResult2",
                                                    "status" => 401,
                                                    "heading" => { "en" => ["Stanford users: log in to access all available features."] },
                                                    "note" => { "en" => ["Access restricted"] }
                                                  })
        end
      end
    end
  end

  context 'when versioned, a Stanford only resource' do
    let(:id) { 'bb000cr7262' }

    let(:public_json) do
      Factories.cocina_with_file(file_access: { 'view' => 'stanford', 'download' => 'stanford' }, file_name:)
    end
    let(:token) { nil }
    let(:stacks_uri) { "https://stacks-uat.stanford.edu/v2/file/#{id}/version/1/#{URI.encode_uri_component(file_name)}" }

    before do
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}", headers: { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
    end

    context 'when the user does not have a token' do
      it 'returns a unauthorized response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "heading" => { "en" => [I18n.t('probe_service.stanford')] },
                                                  "icon" => I18n.t('probe_service.stanford_icon'),
                                                  "status" => 401
                                                })
      end
    end

    context 'when the user has a bearer token with the ldap group' do
      let(:user_webauth_stanford_no_loc) { User.new(webauth_user: true, ldap_groups: %w[stanford:stanford]) }
      let(:token) { user_webauth_stanford_no_loc.token }

      it 'returns a success response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 200
                                                })
      end
    end

    context 'when the user does not provide a token' do
      before do
        get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
      end

      it 'returns a not authorized response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 401,
                                                  "heading" => { "en" => ["Stanford users: log in to access all available features."] },
                                                  "note" => { "en" => ["Access restricted"] }
                                                })
      end

      context 'when object has a hierarchically nested filename' do
        let(:file_name) { 'folder/SC0193_1982-013_b06_f01_1981-09-29.pdf' }

        before do
          get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
        end

        it 'returns a not authorized response' do
          expect(response).to have_http_status :ok
          expect(response.parsed_body).to include({
                                                    "@context" => "http://iiif.io/api/auth/2/context.json",
                                                    "type" => "AuthProbeResult2",
                                                    "status" => 401,
                                                    "heading" => { "en" => ["Stanford users: log in to access all available features."] },
                                                    "note" => { "en" => ["Access restricted"] }
                                                  })
        end
      end
    end
  end

  context 'when the user does not have access to a location restricted resource' do
    let(:public_json) do
      Factories.cocina_with_file(file_access: { 'view' => 'location-based', 'download' => 'location-based',
                                                'location' => location_code })
    end

    before do
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    context 'when special collections' do
      let(:location_code) { 'spec' }
      let(:location) { 'Special Collections reading room' }

      it 'returns a not authorized response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 403,
                                                  "heading" => {
                                                    "en" => [I18n.t('probe_service.location', location:)]
                                                  },
                                                  "note" => { "en" => ["Access restricted"] }
                                                })
      end
    end

    context 'when media & microtext' do
      let(:location_code) { 'm&m' }
      let(:location) { 'Media & Microtext' }

      it 'returns a not authorized response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 403,
                                                  "heading" => {
                                                    "en" => [I18n.t('probe_service.location', location:)]
                                                  },
                                                  "icon" => I18n.t('probe_service.location_icon'),
                                                  "note" => { "en" => ["Access restricted"] }
                                                })
      end
    end
  end

  context 'when the user does not have access to a stanford restricted embargoed resource' do
    let(:public_json) do
      Factories.cocina_with_file(access: { 'embargo' => { "releaseDate" => Time.parse('2099-05-15').getlocal.as_json } },
                                 file_access: { 'view' => 'stanford', 'download' => 'stanford' })
    end

    before do
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    it 'returns a not authorized response' do
      expect(response).to have_http_status :ok
      expect(response.parsed_body).to include({
                                                "@context" => "http://iiif.io/api/auth/2/context.json",
                                                "type" => "AuthProbeResult2",
                                                "status" => 401,
                                                "heading" => {
                                                  "en" =>
                                                    ["Access is restricted to Stanford-affiliated patrons until 2099-05-15."]
                                                },
                                                "note" => { "en" => ["Access restricted"] }
                                              })
    end
  end

  context 'when the resource is download none and a document' do
    let(:public_json) do
      Factories.cocina_with_file(access: {},
                                 file_access: { 'view' => 'none', 'download' => 'none' })
    end

    before do
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    it 'returns a not authorized response' do
      expect(response).to have_http_status :ok
      expect(response.parsed_body).to include({
                                                "@context" => "http://iiif.io/api/auth/2/context.json",
                                                "type" => "AuthProbeResult2",
                                                "status" => 403,
                                                "heading" => {
                                                  "en" => [I18n.t('probe_service.no_download')]
                                                },
                                                "icon" => I18n.t('probe_service.no_download_icon'),
                                                "note" => { "en" => ["Access restricted"] }
                                              })
    end
  end

  context 'when the user does not have access to an embargoed resource' do
    let(:public_json) do
      Factories.cocina_with_file(access: { 'embargo' => { "releaseDate" => Time.parse('2099-05-15').getlocal.as_json } },
                                 file_access: { 'view' => 'none', 'download' => 'none' })
    end

    before do
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    it 'returns a not authorized response' do
      expect(response).to have_http_status :ok
      expect(response.parsed_body).to include({
                                                "@context" => "http://iiif.io/api/auth/2/context.json",
                                                "type" => "AuthProbeResult2",
                                                "status" => 403,
                                                "heading" => { "en" => ["Access is restricted until 2099-05-15."] },
                                                "icon" => I18n.t('probe_service.embargoed_icon'),
                                                "note" => { "en" => ["Access restricted"] }
                                              })
    end
  end
end
