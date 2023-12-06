# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'IIIF auth v2 probe service' do
  let(:id) { 'bb461xx1037' }
  let(:file_name) { 'SC0193_1982-013_b06_f01_1981-09-29.pdf' }
  let(:stacks_uri) { "https://stacks-uat.stanford.edu/file/druid:#{id}/#{file_name}" }
  let(:user) { instance_double(User, locations: [], webauth_user: false, stanford?: false, cdl_tokens: []) }
  let(:ability) { Ability.new(user) }

  # TODO: figure out how to correctly mock Ability object so it doesn't actually try to hit PURL to get rights and parse

  before do
    get "/iiif/auth/v2/probe?id=#{stacks_uri}"
    #allow(ApplicationController).to receive(:current_ability).and_return(ability)
  end

  context 'when the user has access to the resource' do
    let(:file) do
      instance_double(
        StacksFile,
        id:,
        file_name:,
        restricted_by_location?: false,
        stanford_restricted?: false,
        embargoed?: false,
        download: true
      )
    end

    before do
      allow(ability).to receive(:can?).with(:access, file).and_return(false)
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
    let(:file) do
      instance_double(
        StacksFile,
        id:,
        file_name:,
        restricted_by_location?: false,
        stanford_restricted?: true,
        embargoed?: false,
        download: true
      )
    end

    before do
      allow(ability).to receive(:can?).with(:access, file).and_return(false)
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
