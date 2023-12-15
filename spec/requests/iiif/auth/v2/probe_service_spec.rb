# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'IIIF auth v2 probe service' do
  let(:probe_service) { Iiif::Auth::V2::ProbeServiceController }
  let(:id) { 'bb461xx1037' }
  let(:file_name) { 'SC0193_1982-013_b06_f01_1981-09-29.pdf' }
  let(:stacks_uri) { "https://stacks-uat.stanford.edu/file/druid:#{id}/#{URI.encode_uri_component(file_name)}" }
  let(:stacks_uri_param) { URI.encode_uri_component(stacks_uri) }
  let(:public_json) { '{}' }

  # NOTE: For any unauthorized responses, the status from the service is OK...the access status of the resource is in the response body

  # rubocop:disable RSpec/AnyInstance
  before do
    allow(Purl).to receive(:public_json).and_return(public_json)
    allow_any_instance_of(StacksFile).to receive(:readable?).and_return('420')
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
      stub_rights_xml(world_readable_rights_xml)
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    context 'when filename without spaces' do
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

      context 'when uri without druid: prefix' do
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

    before do
      stub_rights_xml(stanford_restricted_rights_xml)
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
    let(:rights_xml) do
      <<-EOF.strip_heredoc
      <rightsMetadata>
          <access type="read">
            <machine>
              <location>#{xml_location}</location>
            </machine>
          </access>
        </rightsMetadata>
      EOF
    end

    before do
      stub_rights_xml(rights_xml)
      get "/iiif/auth/v2/probe?id=#{stacks_uri_param}"
    end

    context 'when special collections' do
      let(:location) { 'spec' }
      let(:xml_location) { 'spec' }

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
      let(:xml_location) { 'm&amp;m' }

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
    let(:rights_xml) do
      <<-EOF.strip_heredoc
      <rightsMetadata>
          <access type="read">
            <machine>
              <embargoReleaseDate>2099-05-15</embargoReleaseDate>
              <group>stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      EOF
    end

    before do
      stub_rights_xml(rights_xml)
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
    let(:rights_xml) do
      <<-EOF.strip_heredoc
      <rightsMetadata>
          <access type="read">
            <machine>
              <embargoReleaseDate>2099-05-15</embargoReleaseDate>
            </machine>
          </access>
        </rightsMetadata>
      EOF
    end

    before do
      stub_rights_xml(rights_xml)
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

  describe '#parse_uri' do
    context 'when URI includes a druid: prefix' do
      it 'parses the druid and filename correctly' do
        expect(probe_service.new.send(:parse_uri, stacks_uri)).to eq({ druid: id, file_name: })
      end
    end

    context 'when URI does not include a druid: prefix' do
      let(:stacks_uri) { "https://stacks-uat.stanford.edu/file/#{id}/#{URI.encode_uri_component(file_name)}" }

      it 'parses the druid and filename correctly' do
        expect(probe_service.new.send(:parse_uri, stacks_uri)).to eq({ druid: id, file_name: })
      end
    end
  end
  # rubocop:enable RSpec/AnyInstance
end
