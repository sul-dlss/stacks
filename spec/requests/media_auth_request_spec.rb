# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Authentication for Media requests", type: :request do

  let(:user_no_loc_no_webauth) { User.new }
  let(:user_webauth_stanford_no_loc) { User.new(webauth_user: true, ldap_groups: %w(stanford:stanford)) }
  let(:druid) { 'bb582xs1304' }

  describe "#auth_check" do
    let(:format) { 'mp4' }
    let(:public_xml) do
      <<-XML
        <publicObject>
          #{rights_xml}
        </publicObject>
      XML
    end

    let(:rights_xml) do
      <<-EOF.strip_heredoc
      <rightsMetadata>
          <access type="read">
            <machine>
              <group>Stanford</group>
            </machine>
          </access>
        </rightsMetadata>
      EOF
    end

    let(:mock_media) do
      sms = StacksMediaStream.new(id: 'bb582xs1304', file_name: 'file', format: format)
      allow(sms).to receive(:public_xml).and_return(public_xml)
      sms
    end

    context 'when the user can read/stream the file' do
      it 'gets the success JSON and a token' do
        allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_webauth_stanford_no_loc)
        allow_any_instance_of(MediaController).to receive(:current_media).and_return(mock_media)
        get "/media/#{druid}/file.#{format}/auth_check.js"
        body = JSON.parse(response.body)
        expect(body['status']).to eq 'success'
        expect(body['token']).to match(/^[a-zA-Z0-9]+/)
      end
    end

    context 'when the user cannot read/stream the file' do
      context 'stanford restricted' do
        it 'indicates that the object is restricted in the json' do
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_no_loc_no_webauth)
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(mock_media)
          get "/media/#{druid}/file.#{format}/auth_check.js"
          body = JSON.parse(response.body)
          expect(body['status']).to eq(['stanford_restricted'])
        end
      end

      context 'location restricted' do
        let(:rights_xml) do
          <<-EOF.strip_heredoc
          <rightsMetadata>
              <access type="read">
                <machine>
                  <location>location1</location>
                </machine>
              </access>
            </rightsMetadata>
          EOF
        end

        it 'indicates that the object is location restricted in the json' do
          allow_any_instance_of(MediaController).to receive(:current_user).and_return(user_no_loc_no_webauth)
          allow_any_instance_of(MediaController).to receive(:current_media).and_return(mock_media)
          get "/media/#{druid}/file.#{format}/auth_check.js"
          body = JSON.parse(response.body)
          expect(body['status']).to eq(['location_restricted'])
        end
      end
    end
  end
end
