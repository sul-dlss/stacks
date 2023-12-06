# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'IIIF auth v2 probe service' do
  let(:id) { 'bb461xx1037' }
  let(:file_name) { 'SC0193_1982-013_b06_f01_1981-09-29.pdf' }
  let(:stacks_uri) { "https://stacks-uat.stanford.edu/file/druid:#{id}/#{file_name}" }

  before do
    allow(Purl).to receive(:public_json).and_return(public_json)
  end

  context 'when the user has access to the resource' do
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

  context 'when the user does not have access to the resource' do
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
      get "/iiif/auth/v2/probe?id=#{stacks_uri}"
    end

    it 'returns a not authorized response' do
      expect(response).to have_http_status :ok # NOTE: response status from service is OK, status of the resource is in the response body
      expect(response.parsed_body).to include({
                                                "@context" => "http://iiif.io/api/auth/2/context.json",
                                                "type" => "AuthProbeResult2",
                                                "status" => 401,
                                                "heading" => { "en" => ["You can't see this"] },
                                                "note" => { "en" => ["Sorry"] }
                                              })
    end
  end
end
