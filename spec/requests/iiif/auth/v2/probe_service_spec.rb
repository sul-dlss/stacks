# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'IIIF auth v2 probe service' do
  let(:id) { 'bb461xx1037' }
  let(:file_name) { 'SC0193_1982-013_b06_f01_1981-09-29.pdf' }
  let(:stacks_uri) { CGI.escape "https://stacks-uat.stanford.edu/file/druid:#{id}/#{file_name}" }
  let(:public_json) { '{}' }

  # NOTE: For any unauthorized responses, the status from the service is OK...the access status of the resource is in the response body

  before do
    allow(Purl).to receive(:public_json).and_return(public_json)
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
      get "/iiif/auth/v2/probe?id=#{stacks_uri}"
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

    # rubocop:disable RSpec/AnyInstance
    context 'when the user is logged in as a Stanford user' do
      let(:user_webauth_stanford_no_loc) { User.new(webauth_user: true, ldap_groups: %w[stanford:stanford]) }
      let(:current_user) { user_webauth_stanford_no_loc }

      before do
        allow_any_instance_of(Iiif::Auth::V2::ProbeServiceController).to receive(:current_user).and_return(current_user)
        get "/iiif/auth/v2/probe?id=#{stacks_uri}"
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
    # rubocop:enable RSpec/AnyInstance

    context 'when the user is not logged in as a Stanford user' do
      before do
        get "/iiif/auth/v2/probe?id=#{stacks_uri}"
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
          get "/iiif/auth/v2/probe?id=#{stacks_uri}"
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
      get "/iiif/auth/v2/probe?id=#{stacks_uri}"
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
      get "/iiif/auth/v2/probe?id=#{stacks_uri}"
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
      get "/iiif/auth/v2/probe?id=#{stacks_uri}"
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
end
