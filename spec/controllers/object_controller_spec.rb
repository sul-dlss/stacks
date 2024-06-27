# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ObjectController do
  render_views

  before do
    allow_any_instance_of(StacksFile).to receive(:path).and_return(Rails.root + 'Gemfile')
  end

  describe '#show' do
    context 'when not logged in' do
      context "with an invalid druid" do
        let(:druid) { 'foo' }

        it 'returns a 404 Not Found' do
          allow(Faraday).to receive(:get).with('https://purl.stanford.edu/foo.json').and_return(
            instance_double(Faraday::Response, status: 404, success?: false)
          )
          get :show, params: { id: 'foo' }
          expect(response).to have_http_status :not_found
        end
      end

      context "with downloadable files" do
        let(:json) do
          {
            'structural' => {
              'contains' => [
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => '36105116040556_0002.pdf',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      },
                      {
                        'filename' => '36105116040556_0002.xml',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      },
                      {
                        'filename' => '36105116040556_0002.jp2',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      }
                    ]
                  }
                },
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => '36105116040556_0003.pdf',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      },
                      {
                        'filename' => '36105116040556_0003.xml',
                        'access' => {
                          'view' => 'world',
                          'download' => 'world'
                        }
                      },
                      {
                        'filename' => '36105116040556_0003.jp2',
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
          }.to_json
        end

        before do
          allow(Faraday).to receive(:get).with('https://purl.stanford.edu/fd063dh3727.json')
                                         .and_return(instance_double(Faraday::Response, success?: true, body: json))
        end

        it 'creates a zip' do
          get :show, params: { id: 'fd063dh3727' }
          entries = ZipTricks::FileReader.new.read_zip_structure(io: StringIO.new(response.body))
          expect(entries.length).to eq 6
        end
      end

      context "with a stanford access file" do
        let(:json) do
          {
            'structural' => {
              'contains' => [
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => 'bb142ws0723_01_sl.mp4',
                        'access' => {
                          'view' => 'stanford',
                          'download' => 'stanford'
                        }
                      },
                      {
                        'filename' => 'bb142ws0723_01_thumb.jp2',
                        'access' => {
                          'view' => 'stanford',
                          'download' => 'stanford'
                        }
                      }
                    ]
                  }
                },
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => 'bb142ws0723_program.pdf',
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
          }.to_json
        end

        before do
          allow(Faraday).to receive(:get).with('https://purl.stanford.edu/bb142ws0723.json')
                                         .and_return(instance_double(Faraday::Response, success?: true, body: json))
        end

        it 'redirects to login' do
          get :show, params: { id: 'bb142ws0723' }
          expect(response).to have_http_status(:found)
          expect(response.headers['Location']).to eq(auth_object_url(id: 'bb142ws0723'))
        end
      end
    end

    context 'when logged in as a stanford user' do
      let(:user) { User.new(webauth_user: true, ldap_groups: %w[stanford:stanford]) }

      before do
        allow_any_instance_of(described_class).to receive(:current_user).and_return(user)
      end

      context "with a stanford access file" do
        let(:json) do
          {
            'structural' => {
              'contains' => [
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => 'bb142ws0723_01_sl.mp4',
                        'access' => {
                          'view' => 'stanford',
                          'download' => 'stanford'
                        }
                      },
                      {
                        'filename' => 'bb142ws0723_01_thumb.jp2',
                        'access' => {
                          'view' => 'stanford',
                          'download' => 'stanford'
                        }
                      }
                    ]
                  }
                },
                {
                  'structural' => {
                    'contains' => [
                      {
                        'filename' => 'bb142ws0723_program.pdf',
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
          }.to_json
        end

        before do
          allow(Faraday).to receive(:get).with('https://purl.stanford.edu/bb142ws0723.json')
                                         .and_return(instance_double(Faraday::Response, success?: true, body: json))
        end

        it 'creates a zip' do
          get :show, params: { id: 'bb142ws0723' }
          entries = ZipTricks::FileReader.new.read_zip_structure(io: StringIO.new(response.body))
          expect(entries.length).to eq 3
        end
      end
    end
  end
end
