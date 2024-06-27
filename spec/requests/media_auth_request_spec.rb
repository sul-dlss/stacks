# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Authentication for Media requests" do
  let(:druid) { 'bb582xs1304' }
  let(:format) { 'mp4' }

  let(:public_json) do
    {
      'structural' => {
        'contains' => [
          {
            'structural' => {
              'contains' => [
                {
                  'filename' => 'file',
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

  let(:mock_media) do
    StacksMediaStream.new(id: 'bb582xs1304', file_name: 'file')
  end

  before do
    allow(Cocina).to receive(:find).and_return(Cocina.new(public_json))
    allow_any_instance_of(MediaController).to receive(:current_user).and_return(user)
    allow_any_instance_of(MediaController).to receive(:current_media).and_return(mock_media)
  end

  context 'when the user is stanford authenticated' do
    let(:user) { User.new(webauth_user: true, ldap_groups: %w(stanford:stanford)) }

    it 'gets the success JSON and a token' do
      get "/media/#{druid}/file.#{format}/auth_check"
      expect(response.parsed_body['status']).to eq 'success'
      expect(response.parsed_body['token']).to match(/^[%a-zA-Z0-9]+/)
    end

    it 'indicates that the object is stanford restricted' do
      get "/media/#{druid}/file.#{format}/auth_check"
      expect(response.parsed_body['access_restrictions']['stanford_restricted']).to be true
    end
  end

  context 'when the user is not authenticated' do
    let(:user) { User.new }

    context 'stanford restricted' do
      it 'indicates that the object is restricted in the json' do
        get "/media/#{druid}/file.#{format}/auth_check"
        expect(response.parsed_body['status']).to eq ['stanford_restricted']
      end
    end

    context 'location restricted' do
      let(:public_json) do
        {
          'structural' => {
            'contains' => [
              {
                'structural' => {
                  'contains' => [
                    {
                      'filename' => 'file',
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

      it 'indicates that the object is location restricted in the json' do
        get "/media/#{druid}/file.#{format}/auth_check"
        expect(response.parsed_body['status']).to eq ['location_restricted']
        expect(response.parsed_body).to eq(
          'status' => %w[location_restricted],
          'location' => { "code" => "spec", "label" => "Special Collections reading room" }
        )
      end
    end

    context 'when the file is embargoed or stanford restricted' do
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
                      'filename' => 'file',
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

      it 'indicates that the object is stanford restricted and embargoed in the json' do
        get "/media/#{druid}/file.#{format}/auth_check"
        expect(response.parsed_body).to eq(
          'status' => %w[stanford_restricted embargoed],
          'embargo' => { 'release_date' => Time.parse('2099-05-15').getlocal.as_json },
          'service' => { "@id" => "http://www.example.com/auth/iiif", "label" => "Stanford-affiliated? Login to play" }
        )
      end
    end

    context 'when the file is embargoed' do
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
                      'filename' => 'file',
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

      it 'indicates that the object is embargoed in the json' do
        get "/media/#{druid}/file.#{format}/auth_check.js"
        expect(response.parsed_body).to eq(
          'status' => ['embargoed'],
          'embargo' => { 'release_date' => Time.parse('2099-05-15').getlocal.as_json }
        )
      end
    end
  end
end
