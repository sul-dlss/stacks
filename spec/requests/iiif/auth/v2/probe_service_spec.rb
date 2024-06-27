# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'IIIF auth v2 probe service' do
  let(:id) { 'nr349ct7889' }
  let(:file_name) { 'image.jp2' }
  let(:stacks_uri) { "https://stacks-uat.stanford.edu/file/druid:#{id}/#{URI.encode_uri_component(file_name)}" }
  let(:stacks_uri_param) { URI.encode_uri_component(stacks_uri) }
  let(:public_json) { '{}' }

  # NOTE: For any unauthorized responses, the status from the service is OK...the access status of the resource is in the response body

  # rubocop:disable RSpec/AnyInstance
  before do
    allow(Purl).to receive(:public_json).and_return(public_json)
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
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    it 'returns a success response' do
      expect(response).to have_http_status :ok
      expect(response.parsed_body).to eq("@context" => "http://iiif.io/api/auth/2/context.json",
                                         "note" => { "en" => ["Id is invalid"] },
                                         "status" => 400,
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

  context 'when the user has access to the resource because it is world accessible' do
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
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    context 'when druid has a prefix' do
      it 'returns a success response' do
        expect(response).to have_http_status :ok
        # Ensure the druid doesn't have a prefix:
        expect(StacksFile).to have_received(:new).with(hash_including(id: "nr349ct7889"))

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
        # Ensure the druid doesn't have a prefix:
        expect(StacksFile).to have_received(:new).with(hash_including(id: "nr349ct7889"))

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
      expect(response.parsed_body.dig('location', 'id')).to start_with 'https://sul-mediaserver.stanford.edu/stacks/_definst_/nr/349/ct/7889/mp4:SC0193_1982-013_b06_f01_1981-09-29.mp4/playlist.m3u8?stacks_token='
    end
  end

  context 'when the requested file does not exist' do
    let(:public_json) { {} }

    before do
      allow_any_instance_of(StacksFile).to receive(:readable?).and_return(nil)
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
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

    context 'when the user has a bearer token with the ldap group' do
      let(:user_webauth_stanford_no_loc) { User.new(webauth_user: true, ldap_groups: %w[stanford:stanford]) }
      let(:token) { user_webauth_stanford_no_loc.token }

      before do
        get "/iiif/auth/v2/probe?id=#{stacks_uri_param}", headers: { 'HTTP_AUTHORIZATION' => "Bearer #{token}" }
      end

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
                                                  "heading" => { "en" => ["Stanford-affiliated? Login to play"] },
                                                  "auth_url" => "http://www.example.com/auth/iiif",
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
                                                    "heading" => { "en" => ["Stanford-affiliated? Login to play"] },
                                                    "auth_url" => "http://www.example.com/auth/iiif",
                                                    "note" => { "en" => ["Access restricted"] }
                                                  })
        end
      end
    end
  end

  context 'when the user does not have access to a location restricted resource' do
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
                      'download' => 'location_based',
                      'location' => location
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
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    context 'when special collections' do
      let(:location) { 'spec' }

      it 'returns a not authorized response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 401,
                                                  "heading" => {
                                                    "en" => ["Content is restricted to location Special Collections reading room"]
                                                  },
                                                  "note" => { "en" => ["Access restricted"] }
                                                })
      end
    end

    context 'when media & microtext' do
      let(:location) { 'm&m' }

      it 'returns a not authorized response' do
        expect(response).to have_http_status :ok
        expect(response.parsed_body).to include({
                                                  "@context" => "http://iiif.io/api/auth/2/context.json",
                                                  "type" => "AuthProbeResult2",
                                                  "status" => 401,
                                                  "heading" => {
                                                    "en" => ["Content is restricted to location Media & Microtext"]
                                                  },
                                                  "note" => { "en" => ["Access restricted"] }
                                                })
      end
    end
  end

  context 'when the user does not have access to a stanford restricted embargoed resource' do
    let(:public_json) do
      {
        'access' => {
          'embargo' => {
            "releaseDate" => Time.parse('2099-05-15').getlocal.as_json
          }
        },
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
                                                    ["Content is both Stanford restricted and embargoed until 2099-05-15"]
                                                },
                                                "note" => { "en" => ["Access restricted"] }
                                              })
    end
  end

  context 'when the user does not have access to an embargoed resource' do
    let(:public_json) do
      {
        'access' => {
          'embargo' => {
            "releaseDate" => Time.parse('2099-05-15').getlocal.as_json
          }
        },
        'structural' => {
          'contains' => [
            {
              'structural' => {
                'contains' => [
                  {
                    'filename' => file_name,
                    'access' => {
                      'view' => 'none',
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
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    it 'returns a not authorized response' do
      expect(response).to have_http_status :ok
      expect(response.parsed_body).to include({
                                                "@context" => "http://iiif.io/api/auth/2/context.json",
                                                "type" => "AuthProbeResult2",
                                                "status" => 401,
                                                "heading" => { "en" => ["Content is embargoed until 2099-05-15"] },
                                                "note" => { "en" => ["Access restricted"] }
                                              })
    end
  end
  # rubocop:enable RSpec/AnyInstance
end
